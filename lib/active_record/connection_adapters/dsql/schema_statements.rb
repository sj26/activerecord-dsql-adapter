# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module DSQL
      module SchemaStatements
        def add_index_options(table_name, column_name, **options) # :nodoc:
          options[:algorithm] = :async
          super
        end
      end
    end
  end
end
