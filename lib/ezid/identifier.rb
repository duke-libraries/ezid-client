module Ezid
  #
  # Represents an EZID identifier as a resource.
  #
  # @api public
  #
  class Identifier

    attr_reader :client
    attr_accessor :id, :shoulder, :metadata, :state

    private :state, :state=, :id=

    # Attributes to display on inspect
    INSPECT_ATTRS = %w( id status target created ).freeze

    # EZID status terms
    PUBLIC = "public".freeze
    RESERVED = "reserved".freeze
    UNAVAILABLE = "unavailable".freeze

    class << self
      attr_accessor :defaults

      # Creates or mints an identifier (depending on arguments)
      # @see #save
      # @return [Ezid::Identifier] the new identifier
      # @raise [Ezid::Error]
      def create(attrs = {})
        identifier = new(attrs)
        identifier.save
      end

      # Retrieves an identifier
      # @return [Ezid::Identifier] the identifier
      # @raise [Ezid::Error] if the identifier does not exist in EZID
      def find(id)
        identifier = new(id: id)
        identifier.reload
      end
    end

    self.defaults = {}

    def initialize(args={})
      @client = args.delete(:client) || Client.new
      @id = args.delete(:id)
      @shoulder = args.delete(:shoulder)
      @state = :new
      self.metadata = Metadata.new args.delete(:metadata)
      update_metadata self.class.defaults.merge(args) # deprecate?
    end

    def inspect
      attrs = if deleted?
                "id=\"#{id}\" DELETED"
              else
                INSPECT_ATTRS.map { |attr| "#{attr}=#{send(attr).inspect}" }.join(", ")
              end
      "#<#{self.class.name} #{attrs}>"
    end

    def to_s
      id
    end

    # Returns the identifier metadata
    # @param refresh [Boolean] - flag to refresh the metadata from EZID if stale (default: `true`)
    # @return [Ezid::Metadata] the metadata
    def metadata(refresh = true)
      refresh_metadata if refresh && stale?
      @metadata
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
      persist
      reset
    end

    # Updates the metadata
    # @param attrs [Hash] the metadata
    # @return [Ezid::Identifier] the identifier
    def update_metadata(attrs={})
      attrs.each { |k, v| send("#{k}=", v) }
      self
    end

    # Is the identifier persisted?
    # @return [Boolean]
    def persisted?
      state == :persisted
    end

    # Has the identifier been deleted?
    # @return [Boolean]
    def deleted?
      state == :deleted
    end

    # Updates the metadata and saves the identifier
    # @param data [Hash] a hash of metadata
    # @return [Ezid::Identifier] the identifier
    # @raise [Ezid::Error]
    def update(data={})
      update_metadata(data)
      save
    end

    # Reloads the metadata from EZID (local changes will be lost!)
    # @return [Ezid::Identifier] the identifier
    # @raise [Ezid::Error]
    def reload
      refresh_metadata
      self
    end

    # Empties the (local) metadata (changes will be lost!)
    # @return [Ezid::Identifier] the identifier
    def reset
      clear_metadata
      self
    end

    # Deletes the identifier from EZID
    # @see http://ezid.cdlib.org/doc/apidoc.html#operation-delete-identifier
    # @return [Ezid::Identifier] the identifier
    # @raise [Ezid::Error]
    def delete
      raise Error, "Only persisted, reserved identifiers may be deleted: #{inspect}." unless deletable?
      client.delete_identifier(id)
      self.state = :deleted
      reset
    end

    # Is the identifier reserved?
    # @return [Boolean]
    def reserved?
      status == RESERVED
    end

    # Is the identifier public?
    # @return [Boolean]
    def public?
      status == PUBLIC
    end

    # Is the identifier unavailable?
    # @return [Boolean]
    def unavailable?
      status =~ /^#{UNAVAILABLE}/
    end

    # Is the identifier deletable?
    # @return [Boolean]
    def deletable?
      persisted? && reserved?
    end

    # Mark the identifier as unavailable
    # @param reason [String] an optional reason 
    # @return [String] the new status
    def unavailable!(reason = nil)
      if persisted? && reserved?
        raise Error, "Cannot make a reserved identifier unavailable."
      end
      if unavailable? and reason.nil?
        return
      end
      value = UNAVAILABLE
      if reason
        value += " | #{reason}"
      end
      self.status = value
    end

    # Mark the identifier as public
    # @return [String] the new status
    def public!
      self.status = PUBLIC
    end

    protected

    def method_missing(method, *args)
      metadata.send(method, *args)
    rescue NoMethodError
      super
    end

    private

    def stale?
      persisted? && metadata(false).empty?
    end

    def refresh_metadata
      response = client.get_identifier_metadata(id)
      self.metadata = Metadata.new response.metadata
      self.state = :persisted
    end

    def clear_metadata
      metadata(false).clear
    end

    def modify
      client.modify_identifier(id, metadata)
    end

    def create_or_mint
      id ? create : mint
    end

    def mint
      response = client.mint_identifier(shoulder, metadata)
      self.id = response.id
    end

    def create
      client.create_identifier(id, metadata)
    end

    def persist
      persisted? ? modify : create_or_mint
      self.state = :persisted
    end

  end
end
