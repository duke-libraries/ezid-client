require "hashie"
require_relative "metadata_transforms/datacite"

module Ezid
  #
  # EZID metadata collection for an identifier.
  #
  # @api private
  #
  class Metadata < Hashie::Mash

    # EZID metadata field/value separator
    ANVL_SEPARATOR = ": "
    # EZID metadata field value separator
    ELEMENT_VALUE_SEPARATOR = " | "
    # Characters to escape in element values on output to EZID
    # @see http://ezid.cdlib.org/doc/apidoc.html#request-response-bodies
    ESCAPE_VALUES_RE = /[%\r\n]/
    # Characters to escape in element names on output to EZID
    # @see http://ezid.cdlib.org/doc/apidoc.html#request-response-bodies
    ESCAPE_NAMES_RE = /[%:\r\n]/
    # Character sequence to unescape from EZID
    # @see http://ezid.cdlib.org/doc/apidoc.html#request-response-bodies
    UNESCAPE_RE = /%\h\h/
    # A comment line
    COMMENT_RE = /^#.*(\r?\n)?/
    # A line continuation
    LINE_CONTINUATION_RE = /\r?\n\s+/
    # A line ending
    LINE_ENDING_RE = /\r?\n/
    # @api private

    #
    # EZID reserved metadata elements
    #
    # @see http://ezid.cdlib.org/doc/apidoc.html#internal-metadata
    #
    COOWNERS   = "_coowners".freeze
    CREATED    = "_created".freeze
    DATACENTER = "_datacenter".freeze
    EXPORT     = "_export".freeze
    OWNER      = "_owner".freeze
    OWNERGROUP = "_ownergroup".freeze
    PROFILE    = "_profile".freeze
    SHADOWEDBY = "_shadowedby".freeze
    SHADOWS    = "_shadows".freeze
    STATUS     = "_status".freeze
    TARGET     = "_target".freeze
    UPDATED    = "_updated".freeze
    RESERVED = [
      COOWNERS, CREATED, DATACENTER, EXPORT, OWNER, OWNERGROUP,
      PROFILE, SHADOWEDBY, SHADOWS, STATUS, TARGET, UPDATED
    ].freeze
    READONLY = [
      CREATED, DATACENTER, OWNER, OWNERGROUP, SHADOWEDBY, SHADOWS, UPDATED
    ].freeze

    # @param data [String, Hash, Ezid::Metadata] the initial data
    # @param default [Object] DO NOT USE!
    #   This param is included for compatibility with Hashie::Mash
    #   and will raise a NotImplementedError if passed a non-nil value.
    def initialize(data=nil, default=nil)
      unless default.nil?
        raise ::NotImplementedError, "ezid-client does not support default metadata values."
      end
      super()
      update(data) if data
    end

    def elements
      warn "[DEPRECATION] `Ezid::Metadata#elements` is deprecated and will be removed in ezid-client 2.0." \
           " Use the `Ezid::Metadata` instance itself instead. (called from #{caller.first})"
      self
    end

    def created
      to_time(_created)
    end

    def updated
      to_time(_updated)
    end

    def update(data)
      super coerce(data)
    end

    def replace(data)
      hsh = coerce(data)

      # Perform additional profile transforms
      MetadataTransformDatacite.inverse(hsh) if hsh["_profile"] == "datacite"

      super hsh
    end

    # Output metadata in EZID ANVL format
    # @see http://ezid.cdlib.org/doc/apidoc.html#request-response-bodies
    # @return [String] the ANVL output
    def to_anvl(include_readonly = true)
      hsh = to_h
      hsh.reject! { |k, v| READONLY.include?(k) } unless include_readonly

      # Perform additional profile transforms
      MetadataTransformDatacite.transform(hsh) if profile == "datacite"

      lines = hsh.map do |name, value|
        element = [escape(ESCAPE_NAMES_RE, name), escape(ESCAPE_VALUES_RE, value)]
        element.join(ANVL_SEPARATOR)
      end
      lines.join("\n").force_encoding(Encoding::UTF_8)
    end

    def to_s
      to_anvl
    end

    protected

    # Overrides Hashie::Mash
    def convert_key(key)
      converted = super
      if RESERVED.include?("_#{converted}")
        "_#{converted}"
      elsif converted =~ /\A(dc|datacite|erc)_/
        converted.sub(/_/, ".")
      else
        converted
      end
    end

    # Overrides Hashie::Mash
    def convert_value(value, duping=false)
      if [self.class, Hash, Array].include?(value.class)
        raise Error, "ezid-client does not support instances of #{value.class} as metadata values." \
                     " Convert an enumerable such as an array to an appropriate string representation first."
      end
      value.to_s
    end

    private

    def to_time(value)
      time = value.to_i
      (time == 0) ? nil : Time.at(time).utc
    end

    # Coerce data into a Hash of elements
    def coerce(data)
      data.respond_to?(:to_h) ? data.to_h : coerce_string(data)
    end

    # Escape string for sending to EZID host
    def escape(regexp, value)
      value.gsub(regexp) { |m| URI.encode_www_form_component(m.force_encoding(Encoding::UTF_8)) }
    end

    # Unescape value from EZID host (or other source)
    def unescape(value)
      value.gsub(UNESCAPE_RE) { |m| URI.decode_www_form_component(m) }
    end

    # Coerce a string of metadata (e.g., from EZID host) into a Hash
    # @note EZID host does not send comments or line continuations.
    def coerce_string(data)
      data.gsub!(COMMENT_RE, "")
      data.gsub!(LINE_CONTINUATION_RE, " ")
      data.split(LINE_ENDING_RE).each_with_object({}) do |line, memo|
        element, value = line.split(ANVL_SEPARATOR, 2)
        memo[unescape(element.strip)] = unescape(value.strip)
      end
    end

  end
end
