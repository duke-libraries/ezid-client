require_relative "identifier_request"

module Ezid
  class DeleteIdentifierRequest < IdentifierRequest
    self.http_method = DELETE
  end
end
