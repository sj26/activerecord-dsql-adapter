# frozen_string_literal: true

require "active_record"

ActiveSupport.on_load(:active_record) do
  ActiveRecord::ConnectionAdapters.register("dsql", "ActiveRecord::ConnectionAdapters::DSQLAdapter", "active_record/connection_adapters/dsql_adapter")
end

module ActiveRecord
  module Tasks
    extend ActiveSupport::Autoload

    autoload :DSQLDatabaseTasks,  "active_record/tasks/dsql_database_tasks"
  end
end

if defined? Rails
  require "active_record/connection_adapters/dsql/railtie"
end
