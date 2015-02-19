require_relative "request"
require_relative "../metadata"

module Ezid
  # @api private
  # @see http://ezid.cdlib.org/doc/apidoc.html#operation-modify-identifier
  class MintIdentifierRequest < Request
    self.http_method = POST
    attr_reader :shoulder, :metadata
    
    def initialize(client, shoulder, metadata)
      @shoulder = shoulder
      @metadata = Metadata.new(metadata)
      super
    end

    def path
      "/shoulder/#{shoulder}"
    end
  end
end
