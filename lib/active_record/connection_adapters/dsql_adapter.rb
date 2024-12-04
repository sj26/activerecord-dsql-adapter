# frozen_string_literal: true

require "aws-sdk-dsql"

require "active_record"
require "active_record/connection_adapters/postgresql_adapter"

module ActiveRecord
  module ConnectionAdapters
    class DSQLAdapter < PostgreSQLAdapter
      ADAPTER_NAME = "DSQL"

      class << self
        def new_client(conn_params)
          conn_params[:sslmode] ||= "require"
          conn_params[:user] ||= "admin"
          conn_params[:dbname] ||= "postgres"

          conn_params[:password] ||= generate_password(conn_params)

          super(conn_params)
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

      # DSQL doesn't support serial or bigserial

      def self.native_database_types # :nodoc:
        @native_database_types ||= begin
          types = NATIVE_DATABASE_TYPES.dup
          types[:primary_key] = "bigint primary key"
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
end
