# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module DSQL
      class Railtie < ::Rails::Railtie
        rake_tasks do
          ActiveRecord::Tasks::DatabaseTasks.register_task("dsql", "ActiveRecord::Tasks::DSQLDatabaseTasks")
        end
      end
    end
  end
end
