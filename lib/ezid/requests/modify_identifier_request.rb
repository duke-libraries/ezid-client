require_relative "identifier_with_metadata_request"
require_relative "../responses/modify_identifier_response"

module Ezid
  #
  # A request to modify the metadata of an identifier
  # @api private
  #
  class ModifyIdentifierRequest < IdentifierWithMetadataRequest

    self.http_method = POST
    self.response_class = ModifyIdentifierResponse

  end
end
