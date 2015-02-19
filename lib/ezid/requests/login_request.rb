require_relative "request"

module Ezid
  class LoginRequest < Request
    self.http_method = GET
    self.path = "/login"

    def handle_response(*)
      super do |response|
        session.open(response.cookie)
      end
    end
  end
end
