require "forwardable"

module Ezid
  #
  # EZID metadata collection for an identifier.
  #
  # @api private
  #
  class Metadata
    extend Forwardable

    attr_reader :elements

    def_delegators :elements, :[], :[]=, :each, :clear, :to_h, :empty?

    class << self
      def metadata_reader(element, alias_as=nil)
        define_method element do
          get(element)
        end
        if alias_as
          alias_method alias_as, element
        end
      end

      def metadata_writer(element, alias_as=nil)
        define_method "#{element}=" do |value|
          set(element, value)
        end
        if alias_as
          alias_method "#{alias_as}=".to_sym, "#{element}=".to_sym
        end
      end

      def metadata_accessor(element, alias_as=nil)
        metadata_reader element, alias_as
        metadata_writer element, alias_as
      end

      def metadata_profile(profile, *elements)
        elements.each do |element|
          profile_element = [profile, element].join(".")
          method = [profile, element].join("_")

          define_method method do
            get(profile_element)
          end

          define_method "#{method}=" do |value|
            set(profile_element, value)
          end
        end
      end
    end

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

    # EZID reserved metadata elements that are read-only
    # @see http://ezid.cdlib.org/doc/apidoc.html#internal-metadata
    READONLY = %w( _owner _ownergroup _shadows _shadowedby _datacenter _created _updated )

    # EZID metadata profiles - a hash of (profile => elements)
    # @see http://ezid.cdlib.org/doc/apidoc.html#metadata-profiles
    # @note crossref is not included because it is a simple element
    PROFILES = {
      dc: [:creator, :title, :publisher, :date, :type],
      datacite: [:creator, :title, :publisher, :publicationyear, :resourcetype],
      erc: [:who, :what, :when]
    }

    PROFILES.each do |profile, elements|
      metadata_profile profile, *elements
    end

    # Accessors for EZID internal metadata elements
    metadata_accessor :_coowners, :coowners
    metadata_accessor :_crossref
    metadata_accessor :_export, :export
    metadata_accessor :_profile, :profile
    metadata_accessor :_status, :status
    metadata_accessor :_target, :target

    # Readers for EZID read-only internal metadata elements
    metadata_reader :_created
    metadata_reader :_datacenter, :datacenter
    metadata_reader :_owner, :owner
    metadata_reader :_ownergroup, :ownergroup
    metadata_reader :_shadowedby, :shadowedby
    metadata_reader :_shadows, :shadows
    metadata_reader :_updated

    # Accessors for
    metadata_accessor :crossref
    metadata_accessor :datacite
    metadata_accessor :erc

    def initialize(data={})
      @elements = coerce(data)
    end

    def created
      to_time _created
    end

    def updated
      to_time _updated
    end

    # Output metadata in EZID ANVL format
    # @see http://ezid.cdlib.org/doc/apidoc.html#request-response-bodies
    # @return [String] the ANVL output
    def to_anvl(include_readonly = true)
      hsh = elements.dup
      hsh.reject! { |k, v| READONLY.include?(k) } unless include_readonly
      lines = hsh.map do |name, value|
        element = [escape(ESCAPE_NAMES_RE, name), escape(ESCAPE_VALUES_RE, value)]
        element.join(ANVL_SEPARATOR)
      end
      lines.join("\n").force_encoding(Encoding::UTF_8)
    end

    def inspect
      "#<#{self.class.name} elements=#{elements.inspect}>"
    end

    def to_s
      to_anvl
    end

    def get(element)
      self[element.to_s]
    end

    def set(element, value)
      self[element.to_s] = value
    end

    protected

    def method_missing(method, *args)
      return get(method) if args.size == 0
      if element = method.to_s[/^([^=]+)=$/, 1]
        return set(element, *args)
      end
      super
    end

    private

    def to_time(value)
      time = value.to_i
      (time == 0) ? nil : Time.at(time).utc
    end

    # Coerce data into a Hash of elements
    def coerce(data)
      data.to_h
    rescue NoMethodError
      coerce_string(data)
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
