module LuckyRecord::Associations
  macro has_many(type_declaration)
    {% assoc_name = type_declaration.var }
    {% model = type_declaration.type %}
    {% foreign_key = "#{@type.name.underscore}_id".id %}
    @_preloaded_{{ assoc_name }} : Array({{ model }})?
    setter _preloaded_{{ assoc_name }}

    class BaseQuery < LuckyRecord::Query
      def preload_{{ assoc_name }}(preload_query : {{ model }}::BaseQuery = {{ model}}::BaseQuery.new)
        add_preload do |records|
          ids = records.map(&.id)
          {{ assoc_name }} = preload_query.{{ foreign_key }}.in(ids).results.group_by(&.{{ foreign_key }})
          records.each do |record|
            record._preloaded_{{ assoc_name }} = {{ assoc_name }}[record.id]? || [] of {{ model }}
          end
        end
        self
      end
    end

    def {{ assoc_name.id }}
      if settings.lazy_load_enabled
        {{ model }}::BaseQuery.new.{{ foreign_key }}(id)
      else
        @_preloaded_{{ assoc_name }} || raise LuckyRecord::LazyLoadError.new
      end
    end
  end

  macro belongs_to(type_declaration)
    {% assoc_name = type_declaration.var }
    {% foreign_key = "#{assoc_name}_id".id %}

    {% if type_declaration.type.is_a?(Union) %}
      {% model = type_declaration.type.types.first %}
      {% nilable = true %}
    {% else %}
      {% model = type_declaration.type %}
      {% nilable = false %}
    {% end %}

    field {{ assoc_name.id }}_id : Int32{% if nilable %}?{% end %}

    def {{ assoc_name.id }}
      if settings.lazy_load_enabled
        {{ foreign_key }}.try do |value|
          {{ model }}::BaseQuery.new.find(value)
        end
      else
        @_preloaded_{{ assoc_name }} || raise LuckyRecord::LazyLoadError.new
      end
    end

    @_preloaded_{{ assoc_name }} : {{ model }}?
    setter _preloaded_{{ assoc_name }}

    class BaseQuery < LuckyRecord::Query
      def preload_{{ assoc_name }}(preload_query : {{ model }}::BaseQuery = {{ model}}::BaseQuery.new)
        add_preload do |records|
          ids = records.map(&.{{ foreign_key }})
          {{ assoc_name }} = preload_query.id.in(ids).results.group_by(&.id)
          records.each do |record|
            record._preloaded_{{ assoc_name }} = {{ assoc_name }}[record.{{ foreign_key }}].first
          end
        end
        self
      end
    end
  end
end
