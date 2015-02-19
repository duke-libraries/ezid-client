require_relative "request"
require_relative "../metadata"

module Ezid
  # @api private
  # @see http://ezid.cdlib.org/doc/apidoc.html#operation-modify-identifier
  class MintIdentifierRequest < Request
    self.http_method = POST
    attr_reader :shoulder, :metadata
    
    def handle_args(*args)
      @shoulder = args.first
      @metadata = Metadata.new(args[1])
    end

    def path
      "/shoulder/#{shoulder}"
    end
  end
end
