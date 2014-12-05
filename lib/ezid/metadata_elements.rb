require "active_support"

module Ezid
  #
  # EZID metadata elements
  #
  # @note Intended to be used only as included in Ezid::Metadata.
  #
  module MetadataElements
    extend ActiveSupport::Concern
    
    # Metadata profiles
    PROFILES = {
      "dc"       => %w( creator title publisher date type ).freeze,
      "datacite" => %w( creator title publisher publicationyear resourcetype ).freeze,
      "erc"      => %w( who what when ).freeze,
      "crossref" => [].freeze
      }

    # Elements for metadata profiles (values may include multiple elements)
    PROFILE_ELEMENTS = PROFILES.keys - ["dc"]

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
    RESERVED_ELEMENTS = RESERVED_READONLY_ELEMENTS + RESERVED_READWRITE_ELEMENTS + RESERVED_TIME_ELEMENTS

    included do
      # "_crossref" does not get a reserved accessor because of the "crossref" element.
      reserved_element_accessor *(RESERVED_READWRITE_ELEMENTS - ["_crossref"])
      reserved_element_reader *(RESERVED_READONLY_ELEMENTS - RESERVED_TIME_ELEMENTS)
      reserved_element_time_reader *RESERVED_TIME_ELEMENTS

      profile_element_accessors
      
      element_accessor *PROFILE_ELEMENTS

      # "_crossref" does not get a reserved accessor because of the "crossref" element.
      element_accessor "_crossref"
    end

    module ClassMethods
      # Creates an accessor for each reserved element
      # @see .reserved_element_reader
      # @see .reserved_element_writer
      # @param elements [Array<String>] a list of elements
      def reserved_element_accessor(*elements)
        reserved_element_reader(*elements)
        reserved_element_writer(*elements)
      end

      # Creates a reader for each reserved element
      #   The leading underscore of the element is removed from the reader name
      #   -- e.g.
      #
      #   def status
      #     reader("_status")
      #   end
      #
      # @param elements [Array<String>] a list of elements
      def reserved_element_reader(*elements)
        elements.each do |element|
          define_method(element.sub("_", "")) { reader(element) }
        end
      end

      # Creates a reader for each time-based reserved element
      #   The reader will return a Time instance for the value (or nil if not present)
      # @see .reserved_element_reader
      # @param elements [Array<String>] a list of elements
      def reserved_element_time_reader(*elements)
        elements.each do |element|
          define_method(element.sub("_", "")) do
            time = reader(element).to_i
            return nil if time == 0 # value is nil or empty string                                                    
            Time.at(time).utc
          end
        end
      end

      # Creates a writer for each reserved element
      #   The leading underscore of the element is removed from the reader name
      #   -- e.g.
      #
      #   def status=(value)
      #     writer("_status", value)
      #   end
      #
      # @param elements [Array<String>] a list of elements
      def reserved_element_writer(*elements)
        elements.each do |element|
          define_method("#{element.sub('_', '')}=") do |value| 
            writer(element, value)
          end
        end
      end

      # Creates a accessors for all metadata profile elements
      def profile_element_accessors
        PROFILES.each do |profile, elements|
          elements.each do |element|
            define_method("#{profile}_#{element}") do
              reader("#{profile}.#{element}")
            end
        
            define_method("#{profile}_#{element}=") do |value|
              writer("#{profile}.#{element}", value)
            end     
          end
        end
      end

      # Creates an accessor for each element
      # @param elements [Array<String>] a list of elements
      def element_accessor(*elements)
        elements.each do |element|
          define_method(element) { reader(element) }
          define_method("#{element}=") { |value| writer(element, value) }
        end
      end
    end

    private

    def reader(element)
      self[element]
    end

    def writer(element, value)
      self[element] = value
    end

  end
end
