# frozen_string_literal: true

require "aws-sdk-dsql"

require "active_record"
require "active_record/connection_adapters/postgresql_adapter"

module ActiveRecord
  module ConnectionAdapters
    module DSQL
      class Railtie < ::Rails::Railtie
        rake_tasks do
          ActiveRecord::DatabaseTasks.register_task("dsql", "ActiveRecord::Tasks::DSQLDatabaseTasks")
        end
      end
    end

    class DSQLAdapter < PostgreSQLAdapter
      ADAPTER_NAME = "DSQL"

      class << self
        def new_client(conn_params)
          conn_params[:sslmode] ||= "require"
          conn_params[:dbname] ||= "postgres"
          conn_params[:user] ||= "admin"
          conn_params[:password] ||= generate_password(conn_params)

          super(conn_params)
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
    end
  end

  module Tasks
    class DSQLDatabaseTasks < PostgreSQLDatabaseTasks
    end
  end
end

ActiveSupport.run_load_hooks(:active_record_dsql_adapter, ActiveRecord::ConnectionAdapters::DSQLAdapter)
