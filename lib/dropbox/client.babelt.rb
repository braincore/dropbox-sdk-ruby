# babelsdk(jinja2)

# This file is auto-generated from the babel template client.babelt.rb.
# Any changes here will silently disappear. And no, this isn't a
# reference to http://stackoverflow.com/a/740603/3862658. Changes will
# actually disappear.
{# TODO If extras['host'] ends up not used, can use this instead: #}
{#% if 'Binary' in op.response_segmentation.segments|map(attribute='data_type')|map(attribute='name') %#}

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

{%- macro required_arg_list(args) -%}
{%- for arg in args -%}
{{ arg.name }}{% if arg.has_default %} = {{ arg.default|pprint }}{% endif %},{{ ' ' }}
{%- endfor -%}
{%- endmacro -%}

{%- macro arg_doc(fields, ns) -%}
{% for field in fields %}
# * +{{ field.name }}+{{ typename(field) }}:{{ ' ' }}
{%- if field.has_default %}(defaults to +{{ field.default|pprint }}+)
{% else %}{# blank block for a newline here #}

{% endif %}
#   {{ ruby_doc_sub(field.doc, ns)|wordwrap(70)|replace('\n', '\n#   ') }}
{% endfor %}
{%- endmacro -%}

{%- macro host(op) -%}
{%- if op.extras['host'] == 'content' -%}
@host_info.api_content_server
{%- else -%}
@host_info.api_server
{%- endif -%}
{%- endmacro -%}

{%- macro input_binary(op) -%}
{%- if op.extras['host'] == 'content' -%}
  {%- for segment in op.request_segmentation.segments -%}
    {%- if segment.data_type.name == 'Binary' -%}
, {{ segment.name|variable }}
    {%- endif -%}
  {%- endfor -%}
{%- endif -%}
{%- endmacro -%}

{%- macro endpoint(op) -%}
{%- if op.extras['host'] == 'content' -%}
do_content_endpoint
{%- else -%}
do_rpc_endpoint
{%- endif -%}
{%- endmacro -%}

{%- macro handle_response(op, indent_spaces) %}
{% filter indent(indent_spaces) %}
{% if op.extras['host'] == 'content' %}
file, metadata = Dropbox::API::HTTP.parse_content_response(response)
  {% if op.response_segmentation.segments[1] %}
return file, Dropbox::API::{{ op.response_segmentation.segments[0].data_type.name|class }}{%- trim -%}
    .from_json(metadata)
  {% else %}
return Dropbox::API::{{ op.response_segmentation.segments[0].data_type.name|class }}{%- trim -%}
    .from_json(metadata)
  {% endif %}
{% else %}
Dropbox::API::{{ op.response_segmentation.segments[0].data_type.name|class }}{%- trim -%}
    .from_json(Dropbox::API::HTTP.parse_rpc_response(response))
{% endif %}
{% endfilter %}
{% endmacro %}

{%- macro typename(field) %}
{%- if field.data_type.composite_type -%}
{{ ' ' }}(+{{ field.data_type.name|class }}+)
{%- else -%}
{{ ' ' }}(+{{ field.data_type|type }}+)
{%- endif -%}
{%- endmacro -%}

{%- macro namespace_def(namespace_name, namespace, indent_spaces) %}
{% filter indent(indent_spaces) %}
class {{ namespace_name|class }} < EndpointNamespace
  def initialize(session)
    super(session)
    @namespace = '{{ namespace_name|lower }}'
  end

  {% for op in namespace.operations %}
  {{ operation_def(op, 2, namespace) }}
  {% endfor %}
end

{% endfilter %}
{% endmacro %}

{%- macro operation_def(op, indent_spaces, ns) -%}
{% filter indent(indent_spaces) %}
{% set request_segment = op.request_segmentation.segments[0].data_type %}
# {{ ruby_doc_sub(op.doc, ns)|wordwrap(70)|replace('\n', '\n# ') }}
#
# Required args:
{{ arg_doc(request_segment.all_required_fields, ns) -}}
{% if op.request_segmentation.segments[1] %}
# * +{{ op.request_segmentation.segments[1].name|variable }}+
#   File-like object
{% endif %}
{% if request_segment.all_optional_fields|length > 0 %}
#
# Optional args:
{{ arg_doc(request_segment.all_optional_fields, ns) -}}
{% endif %}
#
# Returns: {% if op.response_segmentation.segments[1] %}File contents (String), {% endif %}{%- trim -%}
    {{ op.response_segmentation.segments[0].data_type.name|class }}
def {{ op.name|method }}({{ required_arg_list(request_segment.all_required_fields) }}
    {%- if op.request_segmentation.segments[1] -%}
      {{ op.request_segmentation.segments[1].name|variable }},{{ ' ' }}
    {%- endif -%}
    opts = {})
  {% if request_segment.all_optional_fields|length > 0 %}
    {% set first_default = true %}
    {% for field in request_segment.all_optional_fields %}
      {% if field.has_default %}
        {% if first_default %}
  optional_inputs = {
          {% set first_default = false %}
        {% endif %}
    {{ field.name }}: {{ field.default|pprint }},
      {% endif %}
      {% if field == request_segment.all_optional_fields|last %}
        {% if first_default == false %}
  }.merge(opts)
        {% else %}
  optional_inputs = opts
        {% endif %}
      {% endif %}
    {% endfor %}
  {% endif %}
  input_json = {
    {% for field in request_segment.all_fields %}
      {% if field.optional %}
    {{ field.name }}: optional_inputs[:{{ field.name }}],
      {% else %}
    {{ field.name }}: {{ field.name }},
      {% endif %}
    {% endfor %}
  }
  response = @session.{{ endpoint(op) }}({%- trim -%}
    "/#{ @namespace }/{{ op.name|lower|replace('-', '_') }}", input_json{{ input_binary(op) }})
  {{ handle_response(op, 2) }}
end

{% endfilter %}
{% endmacro %}

module Dropbox
  module API

    # Use this class to make Dropbox API calls.  You'll need to obtain an
    # OAuth2 access token first; you can get one using either WebAuth or
    # WebAuthNoRedirect.
    #
    # Methods for API calls are split into namespaces. The Client class
    # stores a reference to each namespace. For example, for file and
    # folder operations:
    #
    #   client = Dropbox::API::Client.new(...)
    #   client.files.info(...) # => Entry object
    class Client

      attr_accessor {{ api.namespaces.keys()|map('inverse_format', ':{0}')|join(', ') }}, :oauth2,
          :client_identifier, :access_token, :locale, :host_info

      # Args:
      # * +oauth2_access_token+: Obtained via WebAuth or WebAuthNoRedirect
      # * +client_identifier+: User agent for client app
      # * +locale+: The user's current locale (used to localize error messages)
      # * +host_info+: Website host addresses for testing. Defaults to the
      #   actual dropbox servers.
      def initialize(oauth2_access_token, client_identifier = '', locale = nil,
                     host_info = nil)
        host_info ||= Dropbox::API::HostInfo.default
        session = Dropbox::API::Session.new(oauth2_access_token,
                                     client_identifier, locale, host_info)
        {% for namespace_name in api.namespaces.keys() %}
        @{{ namespace_name|variable }} = {{ namespace_name|class }}.new(session)
        {% endfor %}
        @oauth2 = OAuth2.new(session)
        @client_identifier = client_identifier
        @access_token = oauth2_access_token
        @locale = locale
        @host_info = host_info
      end

      # Returns a ChunkedUploader object.
      #
      # Args:
      # * +file_obj+: The file-like object to be uploaded. Must support .read()
      # * +total_size+: The total size of file_obj
      def get_chunked_uploader(file_obj, total_size)
        ChunkedUploader.new(self, file_obj, total_size)
      end

      # ChunkedUploader is responsible for uploading a large file to Dropbox
      # in smaller chunks. This allows large files to be uploaded and allows
      # recovery during failure.
      class ChunkedUploader
        attr_accessor :file_obj, :total_size, :offset, :upload_id, :client

        def initialize(client, file_obj, total_size)
          @client = client
          @file_obj = file_obj
          @total_size = total_size
          @upload_id = nil
          @offset = 0
        end

        # Uploads data from this ChunkedUploader's file_obj in chunks, until
        # an error occurs. Throws an exception when an error occurs, and can
        # be called again to resume the upload.
        #
        # Args:
        # * +chunk_size+: The chunk size for each individual upload. Defaults
        #   to 4MB.
        def upload(chunk_size = 4*1024*1024)
          last_chunk = nil

          while @offset < @total_size
            if not last_chunk
              last_chunk = @file_obj.read(chunk_size)
            end

            body, result = @client.files.partial_chunked_upload(last_chunk,
                @upload_id, @offset)
            last_chunk = nil

            if result.offset > @offset
              @offset = result.offset
              last_chunk = nil
            end
            @upload_id = result.upload_id
          end
        end

        # Completes a chunked file upload. See the commit_chunked_upload
        # endpoint documentation.
        def finish(path, write_conflict_policy)
          @client.files.commit_chunked_upload(path, @upload_id, write_conflict_policy)
        end
      end

      private

      # This class divides API endpoints into separate namespaces. Each
      # namespace's endpoints are stored in a different subclass. The outer
      # Client class stores a reference to one of each subclass.
      #
      # Usage example:
      #   client = Client.new(...)
      #   client.files.info('/file/path')
      #   client.users.info('me')
      class EndpointNamespace
        def initialize(session)
          @session = session
        end
      end

      # Endpoints for other oauth methods that aren't covered in the OAuth2
      # module for the authorization flow. The token_from_oauth1 endpoint is
      # not included here because the Dropbox::API::Client object in this SDK
      # only supports OAuth2.
      class OAuth2 < EndpointNamespace
        def initialize(session)
          super(session)
          @namespace = 'oauth2'
        end

        # Disables the access token used by this client.
        def revoke
          @session.do_rpc_endpoint('/revoke')
          nil
        end
      end

      {% for namespace_name, namespace in api.namespaces.items() %}
      {{ namespace_def(namespace_name, namespace, 6) }}
      {% endfor %}
    end
  end
end