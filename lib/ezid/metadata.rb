require "delegate"
require_relative "metadata_elements"

module Ezid
  #
  # EZID metadata collection for an identifier
  #
  # @api public
  #
  class Metadata < SimpleDelegator

    include MetadataElements

    # EZID metadata field/value separator
    ANVL_SEPARATOR = ": "

    ELEMENT_VALUE_SEPARATOR = " | "

    # Characters to escape in element values on output to EZID
    # @see http://ezid.cdlib.org/doc/apidoc.html#request-response-bodies
    ESCAPE_VALUES_RE = /[%\r\n]/

    # Characters to escape in element names on output to EZID
    # @see http://ezid.cdlib.org/doc/apidoc.html#request-response-bodies
    ESCAPE_NAMES_RE = /[%:\r\n]/

    # Character sequence to unescape from EZID
    # http://ezid.cdlib.org/doc/apidoc.html#request-response-bodies
    UNESCAPE_RE = /%\h\h/

    # A comment line
    COMMENT_RE = /^#.*(\r?\n)?/ 

    # A line continuation
    LINE_CONTINUATION_RE = /\r?\n\s+/

    # A line ending
    LINE_ENDING_RE = /\r?\n/
    
    def initialize(data={})
      super(coerce(data))
    end

    # Output metadata in EZID ANVL format
    # @see http://ezid.cdlib.org/doc/apidoc.html#request-response-bodies
    # @return [String] the ANVL output
    def to_anvl(include_readonly = true)
      elements = __getobj__.dup # copy, don't modify!
      elements.reject! { |k, v| RESERVED_READONLY_ELEMENTS.include?(k) } unless include_readonly
      escape_elements(elements).map { |e| e.join(ANVL_SEPARATOR) }.join("\n")
    end

    def to_s
      to_anvl
    end

    private

    # Coerce data into a Hash of elements
    def coerce(data)
      data.to_h
    rescue NoMethodError
      coerce_string(data)
    end

    # Escape elements hash keys and values
    def escape_elements(hsh)
      hsh.each_with_object({}) do |(n, v), memo|
        memo[escape_name(n)] = escape_value(v)
      end
    end

    # Escape an element name
    def escape_name(n)
      escape(ESCAPE_NAMES_RE, n)
    end

    # Escape an element value
    def escape_value(v)
      escape(ESCAPE_VALUES_RE, v)
    end

    # Escape string for sending to EZID host
    # @see http://ezid.cdlib.org/doc/apidoc.html#request-response-bodies
    # @param re [Regexp] the regular expression to match for escaping
    # @param s [String] the string to escape
    # @return [String] the escaped string
    def escape(re, s)
      s.gsub(re) { |m| URI.encode_www_form_component(m.force_encoding(Encoding::UTF_8)) }
    end

    # Unescape value from EZID host (or other source)
    # @see http://ezid.cdlib.org/doc/apidoc.html#request-response-bodies
    # @param value [String] the value to unescape
    # @return [String] the unescaped value
    def unescape(value)
      value.gsub(UNESCAPE_RE) { |m| URI.decode_www_form_component(m) }
    end
    
    # Coerce a string of metadata (e.g., from EZID host) into a Hash
    # @note EZID host does not send comments or line continuations.
    # @param data [String] the string to coerce
    # @return [Hash] the hash of coerced data
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
