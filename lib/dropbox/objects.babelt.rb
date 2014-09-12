# babelsdk(jinja2)

# DO NOT EDIT THIS FILE.
# This file is auto-generated from the babel template objects.babelt.rb.
# Any changes here will silently disappear. And no, this isn't a
# reference to http://stackoverflow.com/a/740603/3862658. Changes will
# actually disappear.

{%- macro struct_doc_ref(s, ns=None) -%}
Dropbox::API::{{ s|class }}
{%- endmacro -%}

{%- macro op_doc_ref(s, ns=None) -%}
Dropbox::API::Client::{{ ns.name|class }}.{{ s|method }}
{%- endmacro -%}

{%- macro field_doc_ref(s, ns=None) -%}
+{{ s }}+
{%- endmacro -%}

{%- macro link_doc_ref(s, ns=None) -%}
{{ s }}
{%- endmacro -%}

{%- macro val_doc_ref(s, ns=None) -%}
{%- if s == 'True' -%}
+true+
{%- elif s == 'False' -%}
+false+
{%- elif s == 'null' -%}
+nil+
{%- else -%}
{{ s }}
{%- endif -%}
{%- endmacro -%}

{%- macro ruby_doc_sub(s, ns=None) -%}
{{ s|doc_sub(ns, struct=struct_doc_ref, op=op_doc_ref, field=field_doc_ref, link=link_doc_ref, val=val_doc_ref) }}
{%- endmacro -%}

{%- macro typename(field) -%}
{%- if field.data_type -%}
{%- if field.data_type.composite_type -%}
{{ ' ' }}(+{{ field.data_type.name|class }}+)
{%- else -%}
{{ ' ' }}(+{{ field.data_type|type }}+)
{%- endif -%}
{%- endif -%}
{%- endmacro -%}

{%- macro arg_doc(fields, ns) -%}
{% for field in fields %}
# * +{{ field.name }}+{{ typename(field) }}{{ ' ' }}
{%- if field.has_default %}(defaults to {{ field.default|pprint }})
{% else %}{# blank block for a newline here #}

{% endif %}
{% if field.doc %}
#   {{ ruby_doc_sub(field.doc, ns)|wordwrap(70)|replace('\n', '\n#   ') }}
{% endif %}
{% endfor %}
{%- endmacro -%}

{%- macro struct_docs(data_type, ns) -%}
{% if data_type.doc %}
# {{ ruby_doc_sub(data_type.doc, ns)|wordwrap(70)|replace('\n', '\n# ') }}
#
{% endif %}
# Required fields:
{{ arg_doc(data_type.all_required_fields, ns) -}}
{% if data_type.all_optional_fields|length > 0 %}
#
# Optional fields:
{{ arg_doc(data_type.all_optional_fields, ns) -}}
{% endif %}
{%- endmacro -%}

{%- macro union_docs(data_type, ns) -%}
{% if data_type.doc %}
# {{ ruby_doc_sub(data_type.doc, ns)|wordwrap(70)|replace('\n', '\n# ') }}
#
{% endif %}
# Member types:
{{ arg_doc(data_type.all_fields, ns) -}}
{%- endmacro -%}

{%- macro arg_list(args, defaults=True) -%}
{% for arg in args %}
{{ arg.name }}
{%- if defaults %}{% if arg.has_default %} = {{ arg.default|pprint }}{% elif arg.optional %} = nil{% endif %}{% endif %},
{% endfor %}
{%- endmacro -%}

{%- macro struct_def(data_type, indent_spaces, ns) -%}
{%- filter indent(indent_spaces, indentfirst=True) -%}
{{ struct_docs(data_type, ns) -}}
class {{ data_type.name|class }}{% if data_type.super_type %} < {{ data_type.super_type.name|class }}{% endif %}

  {% if data_type.fields %}
  attr_accessor(
      {{ data_type.fields|map(attribute='name')|map('inverse_format', ':{0}')|join(',\n      ') }}
  )
  {% endif %}

  def initialize(
      {{ arg_list(data_type.all_fields)|indent(6)|string_slice(0, -1) }}
  )
  {% for field in data_type.all_fields %}
    @{{ field.name }} = {{ field.name }}
  {% endfor %}
  end

  # Initializes an instance of {{ data_type.name|class }} from
  # JSON-formatted data.
  def self.from_json(json)
    self.new(
      {% for field in data_type.all_fields %}
        {%+ if field.nullable -%}
        json['{{ field.name }}'].nil? ? nil :{{ ' ' }}
        {%- elif field.optional -%}
        !json.include?('{{ field.name }}') ? nil :{{ ' ' }}
        {%- endif %}
        {% if field.data_type.composite_type -%}
        {{ field.data_type.name|class }}.from_json(json['{{ field.name }}']),
        {% elif field.data_type.name == 'Timestamp' -%}
        Dropbox::API::convert_date(json['{{ field.name }}']),
        {% elif field.data_type.name == 'List' and field.data_type.data_type.composite_type -%}
        json['{{ field.name }}'].collect { |elem| {{ field.data_type.data_type.name|class }}.from_json(elem) },
        {% else -%}
        json['{{ field.name }}'],
        {% endif %}
      {% endfor %}
    )
  end
end

{% endfilter -%}
{%- endmacro -%}

{%- macro union_def(data_type, indent_spaces, ns) -%}
{%- filter indent(indent_spaces, indentfirst=True) -%}
# This class is a tagged union. For more information on tagged unions,
# see the README.
#
{{ union_docs(data_type, ns) -}}
class {{ data_type.name|class }}

  attr_reader :tag

  # Allowed tags for this union
  TAGS = [{{ data_type.all_fields|map(attribute='name')|map('inverse_format', ':{0}')|join(', ') }}]

  def initialize(tag, val = nil)
    if !TAGS.include?(tag)
        fail ArgumentError, "Invalid symbol '#{ tag }' for this union."
    end
    @tag = tag
    @val = val
  end

  # If the union's type is a symbol field, returns the symbol. Otherwise,
  # returns the value. Alternatively. You can also use each individual
  # attribute accessor to retrieve the value for non-symbol union types.
  def value
    @val.nil? ? @tag : @val
  end

  # Returns this object as a hash for JSON conversion.
  def as_json(options = {})
    if @val.nil?
      @tag.to_s
    else
      { @tag => @val }
    end
  end

  # Initializes an instance of {{ data_type.name|class }} from
  # JSON-formatted data.
  def self.from_json(json)
    if json.is_a?(Hash)
      array = json.flatten
      if array.length != 2
        fail ArgumentError, "JSON should have one key/value pair."
      end
      tag = array[0].to_sym
      val = nil
    {% for field in data_type.all_fields %}
      if tag == :{{ field.name|variable }}
      {% if field.symbol %}
        val = nil
      {% elif field.data_type.composite_type %}
        val = {{ field.data_type.name|class }}.from_json(array[1])
      {% elif field.data_type.name == 'Timestamp' %}
        val = Dropbox::API::convert_date(array[1])
      {% elif field.data_type.name == 'List' and field.data_type.data_type.composite_type %}
        val = array[1].collect { |elem| {{field.data_type.data_type.name|class }}.from_json(array[1]) }
      {% else %}
        val = array[1]
      {% endif %}
      end
    {% endfor %}
    else
      # json is a String
      tag = json.to_sym
      val = nil
    end
    return self.new(tag, val)
  end
{% for field in data_type.all_fields %}

  # Initializes an instance of {{ data_type.name|class }} with the
  # {{ field.name|variable }} tag.
  def self.{{ field.name|method }}
{%- if not field.symbol %}({{ field.name|variable }})
{% else %}{# blank block for a newline here #}

{% endif %}
    self.new(:{{ field.name|variable }}{% if not field.symbol %}, {{ field.name|variable }}{% endif %})
  end

  # Checks if this union has the +{{ field.name|variable }}+ tag.
  def {{ field.name|method }}?
    @tag == :{{ field.name|variable }}
  end
  {% if not field.symbol %}

  # Retrieves the value for this union for the +{{ field.name|variable }}+
  # tag.
  def {{ field.name|method }}
    if @tag == :{{ field.name|variable }}
      @val
    else
      fail "Union is not this type."
    end
  end
  {% endif %}
{% endfor %}
end

{% endfilter -%}
{%- endmacro -%}

{%- macro error_def(data_type, indent_spaces, ns) -%}
{%- filter indent(indent_spaces, indentfirst=True) -%}
class {{ data_type.name|class }} < EndpointError

  def from_json(json, user_message)
    self.new(
        user_message,

    )
  end

end

{% endfilter -%}
{%- endmacro %}

require 'date'

module Dropbox
  module API

    # Converts a string date to a Date object
    def self.convert_date(str)
      DateTime.strptime(str, '%a, %d %b %Y %H:%M:%S')
    end

    {% for namespace in api.namespaces.values() %}
      {% for data_type in namespace.data_types %}
        {% if data_type.composite_type == 'struct' and not data_type.name.endswith('Request') %}
          {{- struct_def(data_type, 4, namespace) }}
        {% elif data_type.composite_type == 'union' and not data_type.name.endswith('Error') %}
          {{- union_def(data_type, 4, namespace) }}
        {% elif data_type.name.endswith('Error') %}
          {{- error_def(data_type, 4, namespace) }}
        {% endif %}
      {% endfor %}
    {% endfor %}

  end
end