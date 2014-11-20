require "forwardable"

module Ezid
  #
  # EZID metadata collection for an identifier
  #
  # @api public
  class Metadata
    extend Forwardable

    attr_reader :elements
    def_delegators :elements, :[], :[]=, :empty?, :to_h, :to_a, :delete_if
    def_delegator :elements, :key?, :has_element?

    # EZID metadata profiles
    PROFILES = %w( erc dc datacite crossref )

    # EZID identifier status values
    PUBLIC = "public"
    RESERVED = "reserved"
    UNAVAILABLE = "unavailable"

    # EZID Internal metadata elements
    INTERNAL_READONLY_ELEMENTS = %w( _owner _ownergroup _created _updated _shadows _shadowedby _datacenter ).freeze
    INTERNAL_READWRITE_ELEMENTS = %w( _coowners _target _profile _status _export _crossref ).freeze        
    INTERNAL_ELEMENTS = (INTERNAL_READONLY_ELEMENTS + INTERNAL_READWRITE_ELEMENTS).freeze

    DATETIME_ELEMENTS = %w( _created _updated ).freeze
    
    ANVL_SEPARATOR = ": ".freeze

    # Creates a reader method for each internal metadata element, 
    # having the same name as the element without the leading underscore
    #
    # def created
    #   self["_created"]
    # end
    #
    INTERNAL_ELEMENTS.each do |element|
      reader = element.sub("_", "").to_sym

      if DATETIME_ELEMENTS.include?(element)
        define_method(reader) do
          Time.at(self[element])
        end
      else
        define_method(reader) do
          self[element]
        end
      end
    end

    # Creates a writer method for each writable internal metadata element
    # having the same base name as the element without the leading underscore.
    # 
    # def status=(value)
    #   self["_status"] = value
    # end
    #
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

    # Adds metadata to the collection
    def update(data)
      elements.update(coerce(data))
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
