# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module DSQL
      class SchemaDumper < PostgreSQL::SchemaDumper # :nodoc:
        private

        def extensions(stream)
          # Ignore extensions
        end
      end
    end
  end
end
