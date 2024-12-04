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

      def configure_connection
        # PostgreSQLAdapter sets a bunch of parameters here which DSQL doesn't support
      end

      # https://docs.aws.amazon.com/aurora-dsql/latest/userguide/working-with-postgresql-compatibility-unsupported-features.html

      def supports_views?
        false
      end

      def supports_materialized_views?
        false
      end

      def supports_extensions?
        false
      end

      def supports_index_sort_order?
        false
      end
    end
  end
end
