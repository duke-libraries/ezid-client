require_relative "request"

module Ezid
  #
  # @abstract
  # @api private
  #
  class IdentifierRequest < Request

    attr_reader :identifier

    def initialize(client, identifier)
      @identifier = identifier
      super
    end

    def path
      "/id/#{identifier}"
    end

  end
end
