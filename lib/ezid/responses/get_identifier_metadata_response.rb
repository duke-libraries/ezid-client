require_relative "identifier_response"

module Ezid
  #
  # Response to a get identifier metadata request
  # @api private
  #
  class GetIdentifierMetadataResponse < IdentifierResponse

    def metadata
      content[1]
    end

  end
end
