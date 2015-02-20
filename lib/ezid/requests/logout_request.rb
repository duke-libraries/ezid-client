require_relative "request"
require_relative "../responses/logout_response"

module Ezid
  #
  # A request to logout of EZID
  # @api private
  #
  class LogoutRequest < Request

    self.http_method = GET
    self.path = "/logout"
    self.response_class = LogoutResponse

    def authentication_required?
      false
    end

  end
end
