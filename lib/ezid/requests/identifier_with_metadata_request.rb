require_relative "identifier_request"

module Ezid
  # @abstract
  # @api private
  class IdentifierWithMetadataRequest < IdentifierRequest
    attr_reader :metadata

    def handle_args(*args)
      super
      @metadata = Metadata.new(args[1])
    end
  end
end
