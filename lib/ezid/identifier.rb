require "forwardable"

require_relative "metadata"

module Ezid
  #
  # An EZID identifier resource
  #
  # @api public 
  class Identifier
    extend Forwardable

    attr_reader :id

    def_delegators :metadata, :status

    class << self
      def create(id, metadata=nil)
        response = Client.create_identifier(id, metadata)
        Identifier.new(response.identifier)
      end

      # Mints an EZID identifier
      def mint(shoulder=nil, metadata=nil)
        response = Client.mint_identifier(metadata)
        identifier = Identifier.new(response.identifier)
      end

      # Find an EZID indentifier
      def find(id)
        response = Client.get_identifier_metadata(id)
        Identifier.new(response.identifier, response.metadata)
      end
    end

    def initialize(id, metadata=nil)
      raise Error, "Cannot initialize an Identifier without an id; use Identifier.mint." if id.nil?
      @id = id
      @metadata = Metadata.new(metadata)
    end

    # The identifier metadata, cached locally
    # @return [Ezid::Metadata] the metadata
    def metadata
      reload if @metadata.empty?
      @metadata
    end

    # The identifier which this identifier is shadowed by, or nil.
    # @return [Ezid::Identifier] the shadowing identifier
    def shadowed_by
      Identifer.new(metadata.shadowedby) if metadata.shadowedby
    end

    # The identifer which this identifier shadows, or nil.
    # @return [Ezid::Identifier] the shadowed identifier
    def shadows
      Identifier.new(metadata.shadows) if metadata.shadows
    end

    # Retrieve the current metadata for the identifier from EZID
    # @return [Ezid::Identifier] the identifier
    def reload
      response = client.get_identifier_metadata(id)
      @metadata = response.metadata
      self
    end

    # Clears the metadata on the identifier object
    # @return [Ezid::Identifier] the identifier
    def reset
      @metadata = Metadata.new
      self
    end

    # Returns an EZID client
    # @return [Ezid::Client] the client
    def client
      @client ||= Client.new
    end

    # Deletes the identifier - caution!
    def delete
      response = client.delete_identifier(id)
      reset
      freeze
      response.message
    end

    # Sends the metadata to EZID - caution!
    def update(metadata)
      response = client.modify_identifier_metadata(metadata)
      reset
      response.message
    end

    def make_public!
      update(_status: Metadata::PUBLIC)
    end

    def make_unavailable!
      update(_status: Metadata::UNAVAILABLE)
    end

    def public?
      status == Metadata::PUBLIC
    end

    def reserved?
      status == Metadata::RESERVED
    end

    def unavailable?
      status == Metadata::UNAVAILABLE
    end

    private

    def remove(*elements)
      metadata = elements.map { |el| [el, ""] }.to_h
      update(metadata)
    end

  end
end
