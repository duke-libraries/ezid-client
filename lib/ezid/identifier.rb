require_relative "metadata"

module Ezid
  class Identifier

    class << self
      def create(id, metadata=nil)
        response = Client.create_identifier(id, metadata)
        Identifier.new(response.identifier)
      end

      def mint(metadata=nil)
        response = Client.mint_identifier(metadata)
        identifier = Identifier.new(response.identifier)
      end

      def find(id)
        response = Client.get_identifier_metadata(id)
        Identifier.new(response.identifier, response.metadata)
      end
    end

    attr_reader :id

    def initialize(id, metadata=nil)
      @id = id
      @metadata = Metadata.new(metadata)
    end

    def metadata
      reload if @metadata.empty?
      @metadata
    end

    def reload
      response = client.get_identifier_metadata(id)
      @metadata.update(response.metadata)
      self
    end

    def client
      @client ||= Client.new
    end

    def save
      response = client.modify_identifier(id, metadata)
      response.success?
    end

    def delete
      response = client.delete_identifier(id)
      response.success?
    end

  end
end
