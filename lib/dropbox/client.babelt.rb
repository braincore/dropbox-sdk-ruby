# babelsdk(jinja2)

{%- macro host(op) -%}
{%- if op.extras['host'] == 'content' -%}
@host_info.api_content_server
{%- else -%}
@host_info.api_server
{%- endif -%}
{%- endmacro -%}

{%- macro input_binary(op) -%}
{%- for segment in op.request_segmentation.segments -%}
{%- if segment.data_type.name == 'Binary' -%}
, {{ segment.name }}
{%- endif -%}
{%- endfor -%}
{%- endmacro -%}

{%- macro args(op) -%}
{%- if op.extras['host'] == 'content' -%}
input{{ input_binary(op) }}
{%- else -%}
input
{%- endif -%}
{%- endmacro -%}

{%- macro endpoint(op) -%}
{%- if op.extras['host'] == 'content' -%}
do_content_endpoint
{%- else -%}
do_rpc_endpoint
{%- endif -%}
{%- endmacro -%}

{%- macro typename(field) %}
{%- if field.data_type.name -%}
{{ ' ' }}(+{{ field.data_type.name }}+)
{%- endif -%}
{%- endmacro -%}

{%- macro operation_def(namespace_name, op, indent_spaces) -%}
{% filter indent(indent_spaces, indentfirst=True) %}
{% set request_fields = op.request_segmentation.segments[0].data_type.fields %}
# {{ op.doc|wordwrap(70)|replace('\n', '\n# ') }}
#
# Args:
{% for field in request_fields %}
# * +{{ field.name }}+{{ typename(field) }}:
#   {{ field.doc|wordwrap(70)|replace('\n', '\n#   ') }}
{% endfor %}
#
# Returns:
#   {{ op.response_segmentation.segments[0].data_type.name|class }}
{# hack: assume url is namespace/op #}
{# hack: assume there's only one input struct with an optional binary after it #}
{# hack: assume if there's more than one field in the response, then the first one is a struct and the second is binary #}
{# TODO add optional/nullable/default arguments #}
def {{ op.name|method }}(
  {%- if op.request_segmentation.segments[0].data_type.fields|length > 0 -%}
    {{ op.request_segmentation.segments[0].data_type.fields|join(' = nil, ', 'name') }} = nil
    {%- if op.request_segmentation.segments[1] -%}
      , {{ op.request_segmentation.segments[1].name|lower }} = nil
    {%- endif -%}
  {%- endif -%}
  )
  input = {
    {% for field in op.request_segmentation.segments[0].data_type.fields %}
      {% if field.name != 'path' %}
    {{ field.name }}: {{ field.name }},
      {% endif %}
    {% endfor %}
  }
  response = @session.{{ endpoint(op) }}({%- trim -%}
    "/{{ namespace_name|lower }}/{{ op.name|lower }}", {{ args(op) }})
  {# hack: assume that a multi-part json response will be a single object for now #}
  {# TODO what if it's a list? #}
  {% if 'Binary' in op.response_segmentation.segments|map(attribute='data_type')|map(attribute='name') %}
  file, metadata = Dropbox::API::HTTP.parse_response(response)
  return file, Dropbox::API::{{ op.response_segmentation.segments[0].data_type.name|class }}{%- trim -%}
      .from_json(metadata)
  {% else %}
  # If this is a multi-part response, this won't work yet.
  Dropbox::API::{{ op.response_segmentation.segments[0].data_type.name|class }}{%- trim -%}
      .from_json(Dropbox::API::HTTP.parse_response(response))
  {% endif %}
end

{% endfilter %}
{%- endmacro %}


module Dropbox
  module API

    # Use this class to make Dropbox API calls.  You'll need to obtain an
    # OAuth 2 access token first; you can get one using either WebAuth or
    # WebAuthNoRedirect.
    class Client

      # Args:
      # * +oauth2_access_token+: Obtained via WebAuth or WebAuthNoRedirect
      # * +client_identifier+: User agent for client app
      # * +root+: root that paths are specified from. Valid values are 'auto'
      #   (default/recommended), 'dropbox', and 'sandbox'
      # * +locale+: The user's current locale (used to localize error messages)
      # * +host_info+: Website host addresses for testing. Defaults to the
      #   actual dropbox servers.
      def initialize(oauth2_access_token, client_identifier = '',
                     root = 'auto', locale = nil, host_info = nil)
        unless oauth2_access_token.is_a?(String)
          fail ArgumentError, "oauth2_access_token must be a String; got "\
                  "#{ oauth2_access_token.inspect }"
        end
        host_info ||= Dropbox::API::HostInfo.default
        @session = Dropbox::API::Session.new(oauth2_access_token,
                                     client_identifier, locale, host_info)
        @root = root.to_s  # If they passed in a symbol, make it a string

        unless ['dropbox', 'app_folder', 'auto'].include?(@root)
          fail ArgumentError, 'root must be "dropbox", "app_folder", or "auto"'
        end

        # App Folder is the name of the access type, but for historical reasons
        # sandbox is the URL root component that indicates this
        if @root == 'app_folder'
          @root = 'sandbox'
        end
      end

      {% for namespace_name, namespace in api.namespaces.items() %}
        {% for op in namespace.operations %}
          {{- operation_def(namespace_name, op, 6) }}
        {% endfor %}
      {% endfor %}

      private

      # From the oauth spec plus "/".  Slash should not be ecsaped
      RESERVED_CHARACTERS = /[^a-zA-Z0-9\-\.\_\~\/]/  # :nodoc:

      def format_path(path, escape = true) # :nodoc:
        # replace multiple slashes with a single one
        path.gsub!(/\/+/, '/')

        # ensure the path starts with a slash
        path.gsub!(/^\/?/, '/')

        # ensure the path doesn't end with a slash
        path.gsub!(/\/?$/, '')

        escape ? URI.escape(path, RESERVED_CHARACTERS) : path
      end

      # Parses out file metadata from a raw dropbox HTTP response.
      #
      # Args:
      # * +response+: The raw, unparsed HTTPResponse from Dropbox.
      #
      # Returns:
      # * The metadata of the file as a hash.
      def parse_metadata(response) # :nodoc:
        begin
          raw_metadata = response['x-dropbox-metadata']
          metadata = JSON.parse(raw_metadata)
        rescue
          raise DropboxError.new("Dropbox Server Error: x-dropbox-metadata=#{raw_metadata}",
                       response)
        end
        return metadata
      end

    end
  end
end