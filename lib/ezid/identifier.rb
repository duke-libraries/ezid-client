module Ezid
  #
  # Represents an EZID identifier as a resource.
  #
  # @api public
  #
  class Identifier

    attr_accessor :id, :shoulder, :persisted, :deleted
    private :persisted=, :persisted, :deleted=, :deleted

    class << self
      attr_accessor :defaults

      # Creates or mints an identifier (depending on arguments)
      # @see #save
      # @overload create(id, metadata=nil)
      #   Creates an identifier
      #   @param id [String] the identifier to create
      #   @param metadata [Hash] the metadata to set on the identifier
      # @overload create(metadata=nil)
      #   Mints an identifier
      #   @deprecated Use {.mint} instead
      #   @param metadata [Hash] the metadata to set on the identifier
      # @return [Ezid::Identifier] the new identifier
      # @raise [Ezid::Error]
      def create(*args)
        raise ArgumentError, "`mint` receives 0-2 arguments." if args.size > 2
        if args.first.is_a?(Hash)
          warn "[DEPRECATION] Sending a hash as the first argument to `create` is deprecated and will raise an exception in 2.0. Use `create(id, metadata)` or `mint(metadata)` instead. (called from #{caller.first})"
          metadata = args.first
          id = metadata.delete(:id)
        else
          id, metadata = args
        end
        if id.nil?
          warn "[DEPRECATION] Calling `create` without an id will raise an exception in 2.0. Use `mint` instead. (called from #{caller.first})"
          shoulder = metadata ? metadata.delete(:shoulder) : nil
          mint(shoulder, metadata)
        else
          new(id, metadata) { |i| i.save }
        end
      end

      # Mints a new identifier
      # @overload mint(shoulder, metadata=nil)
      #   @param shoulder [String] the EZID shoulder on which to mint
      #   @param metadata [Hash] the metadata to set on the identifier
      # @overload mint(metadata=nil)
      #   @param metadata [Hash] the metadata to set on the identifier
      # @return [Ezid::Identifier] the new identifier
      # @raise [Ezid::Error]
      def mint(*args)
        raise ArgumentError, "`mint` receives 0-2 arguments." if args.size > 2
        metadata = args.last.is_a?(Hash) ? args.pop : nil
        new(metadata) do |i|
          i.shoulder = args.first
          i.save
        end
      end

      # Modifies the metadata of an existing identifier.
      # @param id [String] the EZID identifier
      # @param metadata [Hash] the metadata to update on the identifier
      # @return [Ezid::Identifier] the identifier
      # @raise [Ezid::IdentifierNotFoundError]
      def modify(id, metadata)
        i = allocate
        i.id = id
        i.update_metadata(metadata)
        i.modify!
      end

      # Retrieves an identifier
      # @param id [String] the EZID identifier to find
      # @return [Ezid::Identifier] the identifier
      # @raise [Ezid::IdentifierNotFoundError] if the identifier does not exist in EZID
      def find(id)
        i = allocate
        i.id = id
        i.load_metadata
      end
    end

    self.defaults = {}

    def initialize(*args)
      raise ArgumentError, "`new` receives 0-2 arguments." if args.size > 2
      options = args.last.is_a?(Hash) ? args.pop : nil
      @id = args.first
      apply_default_metadata
      if options
        if id = options.delete(:id)
          warn "[DEPRECATION] The `:id` hash option is deprecated and will raise an exception in 2.0. The id should be passed as the first argument to `new` or set explicitly using the attribute writer. (called by #{caller.first})"
          if @id
            raise ArgumentError,
                  "`id' specified in both positional argument and (deprecated) hash option."
          end
          @id = id
        end
        if shoulder = options.delete(:shoulder)
          warn "[DEPRECATION] The `:shoulder` hash option is deprecated and will raise an exception in 2.0. Use `Ezid::Identifier.mint(shoulder, metadata)` to mint an identifier. (called by #{caller.first})"
          @shoulder = shoulder
        end
        if client = options.delete(:client)
          warn "[DEPRECATION] The `:client` hash option is deprecated and ignored. It will raise an exception in 2.0. See the README for details on configuring `Ezid::Client`."
        end
        if anvl = options.delete(:metadata)
          update_metadata(anvl)
        end
        update_metadata(options)
      end
      yield self if block_given?
    end

    def inspect
      id_val = if id.nil?
                 "NEW"
               elsif deleted?
                 "#{id} [DELETED]"
               else
                 id
               end
      "#<#{self.class.name} id=#{id_val}>"
    end

    def to_s
      id
    end

    # Returns the identifier metadata
    # @return [Ezid::Metadata] the metadata
    def metadata(_=nil)
      if !_.nil?
        warn "[DEPRECATION] The parameter of `metadata` is deprecated and will be removed in 2.0. (called from #{caller.first})"
      end
      @metadata ||= Metadata.new
    end

    def remote_metadata
      @remote_metadata ||= Metadata.new
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
      reset_metadata
      self
    end

    # Force a modification of the EZID identifier -- i.e.,
    #   assumes previously persisted without confirmation.
    # @return [Ezid::Identifier] the identifier
    # @raise [Ezid::Error] if `id` is nil
    # @raise [Ezid::IdentifierNotFoundError] if EZID identifier does not exist.
    def modify!
      raise Error, "Cannot modify an identifier without and id." if id.nil?
      modify
      persists!
      reset_metadata
      self
    end

    # Updates the metadata
    # @param attrs [Hash] the metadata
    # @return [Ezid::Identifier] the identifier
    def update_metadata(attrs={})
      metadata.update(attrs)
      self
    end

    # Is the identifier persisted?
    # @return [Boolean]
    def persisted?
      !!persisted
    end

    # Has the identifier been deleted?
    # @return [Boolean]
    def deleted?
      !!deleted
    end

    # Updates the metadata and saves the identifier
    # @param data [Hash] a hash of metadata
    # @return [Ezid::Identifier] the identifier
    # @raise [Ezid::Error]
    def update(data={})
      update_metadata(data)
      save
    end

    # @deprecated Use {#load_metadata} instead.
    def reload
      warn "[DEPRECATION] `reload` is deprecated and will be removed in version 2.0. Use `load_metadata` instead. (called from #{caller.first})"
      load_metadata
    end

    # Loads the metadata from EZID
    # @return [Ezid::Identifier] the identifier
    # @raise [Ezid::Error]
    def load_metadata
      response = client.get_identifier_metadata(id)
      # self.remote_metadata = Metadata.new(response.metadata)
      remote_metadata.replace(response.metadata)
      persists!
      self
    end

    # Empties the (local) metadata (changes will be lost!)
    # @return [Ezid::Identifier] the identifier
    def reset
      warn "[DEPRECATION] `reset` is deprecated and will be removed in 2.0. Use `reset_metadata` instead. (called from #{caller.first})"
      reset_metadata
      self
    end

    # Deletes the identifier from EZID
    # @see http://ezid.cdlib.org/doc/apidoc.html#operation-delete-identifier
    # @return [Ezid::Identifier] the identifier
    # @raise [Ezid::Error]
    def delete
      raise Error, "Only persisted, reserved identifiers may be deleted: #{inspect}." unless deletable?
      client.delete_identifier(id)
      reset_metadata
      self.deleted = true
      self.persisted = false
      self
    end

    # Is the identifier reserved?
    # @return [Boolean]
    def reserved?
      status == Status::RESERVED
    end

    # Is the identifier public?
    # @return [Boolean]
    def public?
      status == Status::PUBLIC
    end

    # Is the identifier unavailable?
    # @return [Boolean]
    def unavailable?
      status.to_s.start_with? Status::UNAVAILABLE
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
      value = Status::UNAVAILABLE
      if reason
        value += " | #{reason}"
      end
      self.status = value
    end

    # Mark the identifier as public
    # @return [String] the new status
    def public!
      self.status = Status::PUBLIC
    end

    def client
      @client ||= Client.new
    end

    def reset_metadata
      metadata.clear unless metadata.empty?
      remote_metadata.clear unless remote_metadata.empty?
    end

    protected

    def method_missing(*args)
      local_or_remote_metadata(*args)
    rescue NoMethodError
      super
    end

    private

    def local_or_remote_metadata(*args)
      value = metadata.send(*args)
      if value.nil? && persisted?
        load_metadata if remote_metadata.empty?
        value = remote_metadata.send(*args)
      end
      value
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
      persists!
    end

    def persists!
      self.persisted = true
    end

    def apply_default_metadata
      update_metadata(self.class.defaults)
    end

  end
end
