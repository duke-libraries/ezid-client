module Ezid
  class Identifier

    attr_reader :id, :client
    attr_accessor :shoulder, :metadata

    INSPECT_ATTRS = %w( id status target created )

    PUBLIC = "public"
    RESERVED = "reserved"
    UNAVAILABLE = "unavailable"

    class << self
      # @return [Ezid::Identifier] the new identifier
      # @raise [Ezid::Error]
      def create(attrs = {})
        identifier = new(attrs)
        identifier.save
      end

      # @return [Ezid::Identifier] the identifier
      # @raise [Ezid::Error] if the identifier does not exist in EZID
      def find(id)
        identifier = new(id: id)
        identifier.reload
      end
    end

    def initialize(args={})
      @client = args.delete(:client) || Client.new
      @id = args.delete(:id)
      @shoulder = args.delete(:shoulder)
      @metadata = Metadata.new(args.delete(:metadata))
      update_attributes(args)
      @deleted = false
    end

    def inspect
      attrs = if deleted?
                "id=\"#{id}\" DELETED"
              else
                INSPECT_ATTRS.map { |attr| "#{attr}=\"#{send(attr)}\"" }.join(" ")
              end
      "#<#{self.class.name} #{attrs}>"
    end

    def to_s
      id
    end

    # Persist the identifer and/or metadata to EZID.
    #   If the identifier is already persisted, this is an update operation;
    #   Otherwise, create (if it has an id) or mint (if it has a shoulder)
    #   the identifier.
    # @return [Ezid::Identifier] the identifier
    # @raise [Ezid::Error] if the identifier is deleted, or the host responds
    #   with an error status.
    def save
      raise Error, "Cannot save a deleted identifier." if deleted?
      if persisted?
        modify
      else
        create_or_mint
      end
      reload
    end

    def update_attributes(attrs={})
      attrs.each { |k, v| send("#{k}=", v) }
    end

    # Is the identifier persisted?
    # @return [Boolean]
    def persisted?
      return false if deleted?
      !!(id && created)
    end

    # Has the identifier been deleted?
    # @return [Boolean]
    def deleted?
      @deleted
    end

    # @return [Ezid::Identifier] the identifier
    # @raise [Ezid::Error]
    def update(data)
      metadata.update(data)
      save
    end

    # @return [Ezid::Identifier] the identifier
    # @raise [Ezid::Error]
    def reload
      refresh_metadata
      self
    end

    # Empties the (local) metadata
    # @return [Ezid::Identifier] the identifier
    def reset
      clear_metadata
      self
    end

    # @return [Ezid::Identifier] the identifier
    # @raise [Ezid::Error]
    def delete
      raise Error, "Status must be \"reserved\" to delete (status: \"#{status}\")." unless reserved?
      client.delete_identifier(id)
      @deleted = true
      reset
    end

    def method_missing(name, *args)
      return metadata.send(name, *args) if metadata.respond_to?(name)
      super
    end

    def reserved?
      status == RESERVED
    end

    def public?
      status == PUBLIC
    end

    def unavailable?
      status == UNAVAILABLE
    end

    private

    def refresh_metadata
      response = client.get_identifier_metadata(id)
      @metadata.replace(response.metadata)
    end

    def clear_metadata
      @metadata.clear
    end

    def modify
      client.modify_identifier(id, metadata)
    end

    def create_or_mint
      if id
        create
      elsif shoulder
        mint
      else
        raise Error, "Unable to create or mint identifier when neither `id' nor `shoulder' present."
      end
    end

    def mint
      response = client.mint_identifier(shoulder, metadata)
      @id = response.id
    end

    def create
      client.create_identifier(id, metadata)
    end

    def init_metadata(args={})
    end

  end
end
