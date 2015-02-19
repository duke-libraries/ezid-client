require_relative "request"

module Ezid
  class LoginRequest < Request
    self.http_method = GET

    def path
      "/login"
    end

    def handle_response(http_response)
      super do |response|
        session.open(response.cookie)
      end
    end
  end
end
