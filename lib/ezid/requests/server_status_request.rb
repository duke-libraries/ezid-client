require_relative "request"

module Ezid
  class ServerStatusRequest < Request
    self.http_method = GET
    attr_reader :subsystems

    def path 
      "/status"
    end

    def query
      "subsystems=#{subsystems.join(',')}"
    end

    def handle_args(*args)
      @subsystems = args
    end

    def handle_response(http_response)
      Status.new(http_response)
    end

    def authentication_required?
      false
    end
  end
end
