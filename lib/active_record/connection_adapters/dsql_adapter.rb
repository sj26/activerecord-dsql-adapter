# frozen_string_literal: true

require "aws-sdk-dsql"

require "active_record"
require "active_record/connection_adapters/postgresql_adapter"

require "aurora_dsql_pg"

module ActiveRecord
  module ConnectionAdapters
    class DSQLAdapter < PostgreSQLAdapter
      ADAPTER_NAME = "DSQL"

      include ActiveRecord::ConnectionAdapters::DSQL::SchemaStatements

      def max_lifetime_seconds
        if @config[:max_lifetime_minutes]
          @config[:max_lifetime_minutes].to_f * 60
        else
          AuroraDsql::Pg::CONFIG[:max_lifetime].to_i
        end
      end

      def token_expired?
        !@token_refreshed_at || Time.now.utc - @token_refreshed_at >= max_lifetime_seconds
      end

      def active?
        return false if token_expired? && !in_transaction?
        super
      end

      def occ_max_retries
        @config[:occ_max_retries].to_i
      end

      def occ_retry_config
        AuroraDsql::Pg::OCCRetry::DEFAULT_CONFIG.merge(max_retries: occ_max_retries)
      end

      private

      def reconnect
        @raw_connection = nil
        connect
        @token_refreshed_at = Time.now.utc
      end

      public

      # we cannot reconnect if in the middle of a transaction
      # as a safety, put padding in max_lifetime_minutes
      def transaction(requires_new: nil, isolation: nil, joinable: true, &block)
        AuroraDsql::Pg::OCCRetry.retry_on_occ(occ_retry_config, logger: ActiveRecord::Base.logger) do
          reconnect! if token_expired?
          super(requires_new:, isolation:, joinable:, &block)
        end
      end

      def with_raw_connection(allow_retry: false, materialize_transactions: true)
        reconnect! if token_expired? && !in_transaction?
        super(allow_retry:, materialize_transactions:) do |conn|
          yield conn
        end
      end

      class << self
        def new_client(conn_params)
          # AuroraDsql::Pg.connect forces sslmode: verify-full!
          # Instead of using that we re-write it here with an optional sslmode override.
          # In development mode using sslmode: require is easier to set up than verify-full.
          # AuroraDsql::Pg.connect(**conn_params)

          config = conn_params
          options = {}
          resolved = AuroraDsql::Pg::Config.from(config, **options).resolve
          token = AuroraDsql::Pg::Token.generate(
            host: resolved.host, region: resolved.region,
            user: resolved.user, credentials: resolved.credentials_provider,
            profile: resolved.profile, expires_in: resolved.token_duration
          )
          pg_params = resolved.to_pg_params(password: token)
          pg_params[:sslmode] = conn_params[:sslmode] if conn_params[:sslmode]
          ::PG.connect(pg_params)
        rescue ::PG::Error => error
          if conn_params && conn_params[:dbname] == "postgres"
            raise ActiveRecord::ConnectionNotEstablished, error.message
          elsif conn_params && conn_params[:dbname] && error.message.include?(conn_params[:dbname])
            raise ActiveRecord::NoDatabaseError.db_error(conn_params[:dbname])
          elsif conn_params && conn_params[:user] && error.message.include?(conn_params[:user])
            raise ActiveRecord::DatabaseConnectionError.username_error(conn_params[:user])
          elsif conn_params && conn_params[:host] && error.message.include?(conn_params[:host])
            raise ActiveRecord::DatabaseConnectionError.hostname_error(conn_params[:host])
          else
            raise ActiveRecord::ConnectionNotEstablished, error.message
          end
        end

        def dbconsole(config, options = {})
          config_hash = config.configuration_hash.dup

          config_hash[:sslmode] ||= "require"
          config_hash[:database] ||= "postgres"
          config_hash[:username] ||= "admin"
          config_hash[:password] ||= generate_password(config_hash)

          config = ActiveRecord::DatabaseConfigurations::HashConfig.new(config.env_name, config.name, config_hash)

          super(config, options)
        end

        private

        def generate_password(conn_params)
          endpoint = conn_params.fetch(:host)
          region = ENV["AWS_REGION"] || ENV["AWS_DEFAULT_REGION"] || "us-east-1"

          credentials = Aws::CredentialProviderChain.new.resolve

          token_generator = Aws::DSQL::AuthTokenGenerator.new(credentials: credentials)

          token_generator.generate_db_connect_admin_auth_token(endpoint: endpoint, region: region)
        end
      end

      # DSQL doesn't support serial or bigserial, nor sequences, but seems to
      # endorse using uuid with default random function uuids for primary keys
      #
      # https://docs.aws.amazon.com/aurora-dsql/latest/userguide/getting-started.html
      #
      def self.native_database_types # :nodoc:
        @native_database_types ||= begin
          types = NATIVE_DATABASE_TYPES.dup
          types[:primary_key] = "uuid primary key unique default gen_random_uuid()"
          types[:datetime] = types[datetime_type]
          types
        end
      end

      # DSQL doesn't support these parameters, but PostgreSQLAdapter always sets them in #configure_connection

      def client_min_messages
        nil
      end

      def client_min_messages=(value)
        nil
      end

      def set_standard_conforming_strings
        nil
      end

      # https://docs.aws.amazon.com/aurora-dsql/latest/userguide/working-with-postgresql-compatibility-unsupported-features.html

      def supports_advisory_locks?
        false
      end

      def supports_views?
        false
      end

      def supports_materialized_views?
        false
      end

      def supports_foreign_keys?
        false
      end

      def supports_exclusion_constraints?
        false
      end

      def supports_extensions?
        false
      end

      def supports_index_sort_order?
        false
      end

      def supports_json?
        false
      end

      # DSQL *does* support DDL transactions, but does not support mixing DDL and
      # DML, so inserting the migration version into the schema_migrations
      # table fails unless we turn off the DDL transaction.
      #
      # PG::FeatureNotSupported: ERROR: ddl and dml are not supported in the same transaction
      #
      def supports_ddl_transactions?
        false
      end

      def index_algorithms
        { async: "ASYNC" }
      end

      # Ignore DSQL sys schema.
      #
      # https://docs.aws.amazon.com/aurora-dsql/latest/userguide/working-with-systems-tables.html
      #
      def schema_names
        super - ["sys"]
      end

      # DSQL creates a primary key index which INCLUDES all columns in the
      # table. We use indnkeyatts to only take notice of key (not INCLUDE-ed)
      # columns for the primary key.
      #
      # https://www.postgresql.org/docs/current/catalog-pg-index.html
      #
      def primary_keys(table_name) # :nodoc:
        query_values(<<~SQL, "SCHEMA")
          SELECT a.attname
            FROM (
                   SELECT indrelid, indnkeyatts, indkey, generate_subscripts(indkey, 1) idx
                     FROM pg_index
                    WHERE indrelid = #{quote(quote_table_name(table_name))}::regclass
                      AND indisprimary
                 ) i
            JOIN pg_attribute a
              ON a.attrelid = i.indrelid
             AND a.attnum = i.indkey[i.idx]
           WHERE i.idx < i.indnkeyatts
           ORDER BY i.idx
        SQL
      end

      def create_schema_dumper(options) # :nodoc:
        DSQL::SchemaDumper.create(self, options)
      end
    end
  end
end

ActiveSupport.run_load_hooks(:active_record_dsql_adapter, ActiveRecord::ConnectionAdapters::DSQLAdapter)
