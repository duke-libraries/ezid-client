require_relative "request"

module Ezid
  class LogoutRequest < Request
    self.http_method = GET

    def path
      "/logout"
    end

    def authentication_required?
      false
    end

    def handle_response(http_response)
      super do |response|
        session.close          
      end
    end
  end
end
