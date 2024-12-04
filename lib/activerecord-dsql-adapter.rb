# frozen_string_literal: true

require "active_record"
require "active_record/connection_adapters"

ActiveRecord::ConnectionAdapters.register("dsql", "ActiveRecord::ConnectionAdapters::DSQLAdapter", "active_record/connection_adapters/dsql_adapter")
