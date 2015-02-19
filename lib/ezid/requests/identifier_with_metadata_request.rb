require_relative "identifier_request"

module Ezid
  # @abstract
  # @api private
  class IdentifierWithMetadataRequest < IdentifierRequest
    attr_reader :metadata

    def initialize(client, identifier, metadata)
      @metadata = Metadata.new(metadata)
      super
    end
  end
end
