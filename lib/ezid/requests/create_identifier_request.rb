require_relative "identifier_with_metadata_request"
require_relative "../responses/create_identifier_response"

module Ezid
  #
  # A request to create (PUT) an identifier in EZID
  # @api private
  #
  class CreateIdentifierRequest < IdentifierWithMetadataRequest

    self.http_method = PUT
    self.response_class = CreateIdentifierResponse

  end
end
