require_relative "request"
require_relative "../responses/status_response"

module Ezid
  class ServerStatusRequest < Request
    self.http_method = GET
    self.path = "/status"

    attr_reader :subsystems

    def initialize(client, *args)
      @subsystems = args
      super
    end

    def query
      "subsystems=#{subsystems.join(',')}"
    end

    def authentication_required?
      false
    end

    def response_class
      StatusResponse
    end
  end
end
