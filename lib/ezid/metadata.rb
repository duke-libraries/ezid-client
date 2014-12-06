require "delegate"
require "singleton"

module Ezid
  #
  # EZID metadata collection for an identifier
  #
  # @note Although this API is not private, its direct use is discouraged.
  #   Instead use the metadata element accessors through Ezid::Identifier.
  # @api public
  #
  class Metadata < SimpleDelegator

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
    # @see http://ezid.cdlib.org/doc/apidoc.html#request-response-bodies
    UNESCAPE_RE = /%\h\h/

    # A comment line
    COMMENT_RE = /^#.*(\r?\n)?/ 

    # A line continuation
    LINE_CONTINUATION_RE = /\r?\n\s+/

    # A line ending
    LINE_ENDING_RE = /\r?\n/
    
    # A metadata element
    Element = Struct.new(:name, :writer)
    
    # Metadata profiles
    PROFILES = {
      "dc"       => %w( creator title publisher date type ).freeze,
      "datacite" => %w( creator title publisher publicationyear resourcetype ).freeze,
      "erc"      => %w( who what when ).freeze,
      "crossref" => [].freeze
      }.freeze

    # EZID reserved metadata elements that have time values
    # @see http://ezid.cdlib.org/doc/apidoc.html#internal-metadata
    RESERVED_TIME_ELEMENTS = %w( _created _updated )

    # EZID reserved metadata elements that are read-only
    # @see http://ezid.cdlib.org/doc/apidoc.html#internal-metadata
    RESERVED_READONLY_ELEMENTS = %w( _owner _ownergroup _shadows _shadowedby _datacenter _created _updated )

    # EZID reserved metadata elements that may be set by clients
    # @see http://ezid.cdlib.org/doc/apidoc.html#internal-metadata
    RESERVED_READWRITE_ELEMENTS = %w( _coowners _target _profile _status _export _crossref )

    # All EZID reserved metadata elements
    # @see http://ezid.cdlib.org/doc/apidoc.html#internal-metadata
    RESERVED_ELEMENTS = RESERVED_READONLY_ELEMENTS + RESERVED_READWRITE_ELEMENTS

    # Metadata element registry
    class ElementRegistry < SimpleDelegator
      include Singleton

      def initialize
        super(Hash.new)
      end

      def readers
        keys
      end

      def writers
        keys.select { |k| self[k].writer }.map(&:to_s).map { |k| k.concat("=") }.map(&:to_sym)
      end
    end

    def self.initialize!
      register_elements
      define_element_accessors
    end

    def self.elements
      ElementRegistry.instance
    end

    def self.register_elements
      register_profile_elements
      register_reserved_elements
      elements.freeze
    end

    def self.define_element_accessors
      elements.each do |accessor, element|
        define_method(accessor) { reader(element.name) }
      
        if element.writer
          define_method("#{accessor}=") { |value| writer(element.name, value) }
        end
      end
    end

    def self.register_element(accessor, element, opts={})
      writer = opts.fetch(:writer, true)
      elements[accessor] = Element.new(element, writer).freeze
    end

    def self.register_profile_elements
      PROFILES.each do |profile, profile_elements|
        profile_elements.each do |element|
          register_element("#{profile}_#{element}".to_sym, "#{profile}.#{element}")
        end
        register_element(profile.to_sym, profile) unless profile == "dc"
      end
    end

    def self.register_reserved_elements
      RESERVED_ELEMENTS.each do |element|
        accessor = ((element == "_crossref") ? element : element.sub("_", "")).to_sym
        register_element(accessor, element, writer: RESERVED_READWRITE_ELEMENTS.include?(element))
      end
    end

    private_class_method :register_element, :register_elements, :register_reserved_elements, 
                         :register_profile_elements, :define_element_accessors

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

      def reader(element)
        value = self[element]
        if RESERVED_TIME_ELEMENTS.include?(element)
          time = value.to_i
          value = (time == 0) ? nil : Time.at(time).utc
        end
        value
      end

      def writer(element, value)
        self[element] = value
      end

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

Ezid::Metadata.initialize!
