require "delegate"

module Ezid
  #
  # EZID metadata collection for an identifier.
  #
  # @api private
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
    Element = Struct.new(:name, :reader, :writer)

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

    def self.initialize!
      register_elements
    end

    def self.registered_elements
      @@registered_elements ||= {}
    end

    def self.register_elements
      register_profile_elements
      register_reserved_elements
    end

    def self.register_element(accessor, opts={})
      if element = registered_elements[accessor.to_sym]
        raise Error, "Element \"#{element.name}\" is registered under the accessor :#{accessor}."
      end
      element = Element.new(opts.fetch(:name, accessor.to_s))
      element.reader = define_reader(accessor, element.name)
      element.writer = define_writer(accessor, element.name) if opts.fetch(:writer, true)
      registered_elements[accessor.to_sym] = element
    end

    def self.unregister_element(accessor)
      element = registered_elements.delete(accessor)
      raise Error, "No element is registered under the accessor :#{accessor}." unless element
      remove_method(element.reader)
      remove_method(element.writer) if element.writer
    end

    def self.register_profile_element(profile, element)
      register_element("#{profile}_#{element}", name: "#{profile}.#{element}")
    end

    def self.register_profile_elements(profile = nil)
      if profile
        PROFILES[profile].each { |element| register_profile_element(profile, element) }
      else
        PROFILES.keys.each do |profile|
          register_profile_elements(profile)
          register_element(profile) unless profile == "dc"
        end
      end
    end

    def self.register_reserved_elements
      RESERVED_ELEMENTS.each do |element|
        accessor = (element == "_crossref") ? element : element.sub("_", "")
        register_element(accessor, name: element, writer: RESERVED_READWRITE_ELEMENTS.include?(element))
      end
    end

    def self.define_reader(accessor, element)
      define_method(accessor) do
        reader(element)
      end
    end

    def self.define_writer(accessor, element)
      define_method("#{accessor}=") do |value|
        writer(element, value)
      end
    end

    private_class_method :register_elements,
                         :register_reserved_elements,
                         :register_profile_elements,
                         :unregister_element,
                         :define_reader,
                         :define_writer

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

    def registered_elements
      self.class.registered_elements
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
