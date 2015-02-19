require_relative "identifier_request"
require_relative "../responses/get_identifier_metadata_response"

module Ezid
  #
  # A request to get the metadata of an identifier
  # @api private
  #
  class GetIdentifierMetadataRequest < IdentifierRequest

    self.http_method = GET
    self.response_class = GetIdentifierMetadataResponse

  end
end
