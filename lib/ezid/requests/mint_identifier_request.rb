require_relative "request"
require_relative "../metadata"
require_relative "../responses/mint_identifier_response"

module Ezid
  #
  # A request to EZID to mint a new identifier
  # @api private
  # @see http://ezid.cdlib.org/doc/apidoc.html#operation-modify-identifier
  #
  class MintIdentifierRequest < Request

    self.http_method = POST
    self.response_class = MintIdentifierResponse

    attr_reader :shoulder, :metadata

    def initialize(client, shoulder, metadata)
      @shoulder = shoulder
      @metadata = Metadata.new(metadata)
      super
    end

    def path
      "/shoulder/#{shoulder}"
    end

  end
end
