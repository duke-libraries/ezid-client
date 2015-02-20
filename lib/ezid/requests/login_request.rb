require_relative "request"
require_relative "../responses/login_response"

module Ezid
  #
  # A request to login to EZID
  # @api private
  #
  class LoginRequest < Request

    self.http_method = GET
    self.path = "/login"
    self.response_class = LoginResponse

  end
end
