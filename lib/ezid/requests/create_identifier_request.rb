require_relative "identifier_with_metadata_request"

module Ezid
  class CreateIdentifierRequest < IdentifierWithMetadataRequest
    self.http_method = PUT
  end
end
