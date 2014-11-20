require "forwardable"

module Ezid
  class Metadata
    extend Forwardable

    attr_reader :elements
    def_delegators :elements, :[], :[]=, :empty?, :to_h, :to_a, :delete_if
    def_delegator :elements, :key?, :has_element?

    # EZID metadata profiles
    PROFILES = %w( erc dc datacite crossref )

    # EZID identifier status values
    STATUS_VALUES = %w( public reserved unavailable )

    # EZID Internal metadata elements
    INTERNAL_READONLY_ELEMENTS = %w( _owner _ownergroup _created _updated _shadows _shadowedby _datacenter ).freeze
    INTERNAL_READWRITE_ELEMENTS = %w( _coowners _target _profile _status _export _crossref ).freeze        
    INTERNAL_ELEMENTS = (INTERNAL_READONLY_ELEMENTS + INTERNAL_READWRITE_ELEMENTS).freeze
    
    ANVL_SEPARATOR = ": ".freeze

    # Creates a reader method for each internal metadata element
    INTERNAL_ELEMENTS.each do |element|
      reader = element.sub("_", "").to_sym
      define_method(reader) do
        self[element]
      end
    end

    # Creates a writer method for each writable internal metadata element
    INTERNAL_READWRITE_ELEMENTS.each do |element|
      writer = "#{element.sub('_', '')}=".to_sym
      define_method(writer) do |value|
        self[element] = value
      end
    end

    # @param data [Hash, String, Ezid::Metadata] EZID metadata
    def initialize(data={})
      @elements = coerce(data)
    end

    # @todo escape \n, \r and %
    # @todo force UTF-8
    # @see http://ezid.cdlib.org/doc/apidoc.html#request-response-bodies
    def to_anvl(exclude_readonly = false)      
      to_a.map { |pair| pair.join(ANVL_SEPARATOR) }.join("\n")
    end

    def to_s
      to_anvl
    end

    # Add metadata
    def update(data)
      elements.update(coerce(data))
    end

    # # EZID deletes a metadata element by setting its value to the empty string
    # def delete(element)
    #   self[element] = "" if has_element?(element)
    # end

    def remove_readonly_elements!
      delete_if { |element, v| INTERNAL_READONLY_ELEMENTS.include?(element) }
    end

    private

    # Coerce data into a Hash of elements
    # @todo unescape 
    # @see {#to_anvl}
    def coerce(data)
      begin
        data.to_h
      rescue NoMethodError
        # This does not account for comments and continuation lines
        # http://ezid.cdlib.org/doc/apidoc.html#request-response-bodies
        data.split(/\r?\n/).map { |line| line.split(ANVL_SEPARATOR, 2) }.to_h
      end
    end

  end
end
