# frozen_string_literal: true

require "active_record"
require "active_record/tasks/postgresql_database_tasks"

module ActiveRecord
  module Tasks
    class DSQLDatabaseTasks < PostgreSQLDatabaseTasks
      def initialize(config)
        config_hash = config.configuration_hash.dup

        config_hash[:sslmode] ||= "require"
        config_hash[:database] ||= "postgres"
        config_hash[:username] ||= "admin"

        config = ActiveRecord::DatabaseConfigurations::HashConfig.new(config.env_name, config.name, config_hash)

        super(config)
      end

      def create(...)
        fail "DSQL does not support CREATE DATABASE"
      end

      def drop(...)
        fail "DSQL does not support DROP DATABASE"
      end
    end
  end
end
