require_relative "request"

module Ezid
  class LogoutRequest < Request
    self.http_method = GET
    self.path = "/logout"

    def authentication_required?
      false
    end

    def handle_response(*)
      super do |response|
        session.close          
      end
    end
  end
end
