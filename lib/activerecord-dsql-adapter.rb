# frozen_string_literal: true

require "active_support/lazy_load_hooks"

ActiveSupport.on_load(:active_record) do
  ActiveRecord::ConnectionAdapters.register("dsql", "ActiveRecord::ConnectionAdapters::DSQLAdapter", "active_record/connection_adapters/dsql_adapter")
end
