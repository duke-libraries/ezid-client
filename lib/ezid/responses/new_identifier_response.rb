require_relative "identifier_response"

module Ezid
  #
  # A response to a mint or create request to make a new identifier in EZID
  # @api private
  #
  class NewIdentifierResponse < IdentifierResponse

    SHADOW_ARK_RE = /\| (ark:[^\s]+)/

    def shadow_ark
      @shadow_ark ||= SHADOW_ARK_RE.match(message)[1]
    end

  end
end
