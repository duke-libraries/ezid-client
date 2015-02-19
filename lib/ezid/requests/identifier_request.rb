require_relative "request"

module Ezid
  # @abstract
  # @api private
  class IdentifierRequest < Request
    attr_reader :identifier

    def path
      "/id/#{identifier}"
    end

    def initialize(client, identifier)
      @identifier = identifier
      super
    end
  end
end
