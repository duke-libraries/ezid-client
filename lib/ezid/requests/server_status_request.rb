require_relative "request"
require_relative "../responses/server_status_response"

module Ezid
  #
  # A request for the EZID server status
  # @api private
  #
  class ServerStatusRequest < Request

    self.http_method = GET
    self.path = "/status"
    self.response_class = ServerStatusResponse

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

  end
end
