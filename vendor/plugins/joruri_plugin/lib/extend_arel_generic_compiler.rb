module Arel
  module SqlCompiler
    class GenericCompiler
      def insert_sql(include_returning = true)
        insertion_attributes_values_sql = if relation.record.is_a?(Value)
          relation.record.value
        else
          attributes = relation.record.keys.sort_by do |attribute|
            attribute.name.to_s
          end

          first = attributes.collect do |key|
            @engine.connection.quote_column_name(key.name)
          end.join(', ')

          second = attributes.collect do |key|
            key.format(relation.record[key]).dup.force_encoding('UTF-8')
          end.join(', ')

          build_query "(#{first})", "VALUES (#{second})"
        end

        build_query \
          "INSERT",
          "INTO #{relation.table_sql}",
          insertion_attributes_values_sql,
          ("RETURNING #{engine.connection.quote_column_name(relation.primary_key)}" if include_returning && relation.compiler.supports_insert_with_returning?)
      end
    end
  end
end