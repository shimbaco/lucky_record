module LuckyRecord::Associations
  macro has_many(type_declaration)
    {% assoc_name = type_declaration.var }
    {% model = type_declaration.type %}
    @_preloaded_{{ assoc_name }} : Array({{ model }})?
    setter _preloaded_{{ assoc_name }}

    class BaseQuery < LuckyRecord::Query
      def preload_{{ assoc_name }}
        preload do |ids|
          {{ model }}::BaseQuery.new.post_id.in(ids).results.group_by(&.post_id)
        end
        self
      end
    end

    def {{ assoc_name.id }}
      if settings.lazy_load_enabled
        {{ model }}::BaseQuery.new.{{ @type.name.underscore }}_id(id)
      else
        @_preloaded_{{ assoc_name }} || raise LuckyRecord::LazyLoadError.new
      end
    end
  end

  macro belongs_to(type_declaration)
    {% assoc_name = type_declaration.var }

    {% if type_declaration.type.is_a?(Union) %}
      {% model = type_declaration.type.types.first %}
      {% nilable = true %}
    {% else %}
      {% model = type_declaration.type %}
      {% nilable = false %}
    {% end %}

    field {{ assoc_name.id }}_id : Int32{% if nilable %}?{% end %}

    def {{ assoc_name.id }}
      {{ assoc_name.id }}_id.try do |value|
        {{ model }}::BaseQuery.new.find(value)
      end
    end
  end
end
