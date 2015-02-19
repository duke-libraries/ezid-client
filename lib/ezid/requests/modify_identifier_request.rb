require_relative "identifier_with_metadata_request"

module Ezid
  class ModifyIdentifierRequest < IdentifierWithMetadataRequest
    self.http_method = POST
  end
end
