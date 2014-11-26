require "active_support"

module Ezid
  module MetadataElements
    extend ActiveSupport::Concern
    
    DC_ELEMENTS = %w( creator title publisher date type )
    DATACITE_ELEMENTS = %w( creator title publisher publicationyear resourcetype )
    ERC_ELEMENTS = %w( who what when )

    RESERVED_TIME_ELEMENTS = %w( _created _updated )
    RESERVED_READONLY_ELEMENTS = %w( _owner _ownergroup _shadows _shadowedby _datacenter _created _updated )
    RESERVED_READWRITE_ELEMENTS = %w( _coowners _target _profile _status _export _crossref )
    RESERVED_ELEMENTS = RESERVED_READONLY_ELEMENTS + RESERVED_READWRITE_ELEMENTS + RESERVED_TIME_ELEMENTS

    included do
      reserved_accessor *(RESERVED_READWRITE_ELEMENTS - ["_crossref"])
      reserved_reader *(RESERVED_READONLY_ELEMENTS - RESERVED_TIME_ELEMENTS)
      reserved_time_reader *RESERVED_TIME_ELEMENTS

      profile_accessor :dc, *DC_ELEMENTS
      profile_accessor :datacite, *DATACITE_ELEMENTS
      profile_accessor :erc, *ERC_ELEMENTS
      
      element_accessor "datacite", "crossref", "_crossref"
    end

    module ClassMethods
      def reserved_accessor(*elements)
        reserved_reader(*elements)
        reserved_writer(*elements)
      end

      def reserved_reader(*elements)
        elements.each do |element|
          define_method(element.sub("_", "")) { reader(element) }
        end
      end

      def reserved_time_reader(*elements)
        elements.each do |element|
          define_method(element.sub("_", "")) do
            time = reader(element).to_i
            return nil if time == 0 # value is nil or empty string                                                    
            Time.at(time).utc
          end
        end
      end

      def reserved_writer(*elements)
        elements.each do |element|
          define_method("#{element.sub('_', '')}=") do |value| 
            writer(element, value)
          end
        end
      end

      def profile_accessor(profile, *elements)
        elements.each do |element|
          define_method("#{profile}_#{element}") do
            reader("#{profile}.#{element}")
          end
        
          define_method("#{profile}_#{element}=") do |value|
            writer("#{profile}.#{element}", value)
          end     
        end
      end

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
