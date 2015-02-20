require_relative "identifier_request"
require_relative "../responses/delete_identifier_response"

module Ezid
  class DeleteIdentifierRequest < IdentifierRequest

    self.http_method = DELETE
    self.response_class = DeleteIdentifierResponse

  end
end
