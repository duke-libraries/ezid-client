require_relative "response"

module Ezid
  class IdentifierResponse < Response

    IDENTIFIER_RE = /^(doi|ark|urn):[^\s]+/

    def id
      @id ||= IDENTIFIER_RE.match(message)[0]
    end

  end
end
