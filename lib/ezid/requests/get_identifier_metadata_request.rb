require_relative "identifier_request"

module Ezid
  class GetIdentifierMetadataRequest < IdentifierRequest
    self.http_method = GET
  end
end
