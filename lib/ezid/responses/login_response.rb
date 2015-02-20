require_relative "response"

module Ezid
  # 
  # Response to a login request
  # @api private
  #
  class LoginResponse < Response

    def cookie
      self["Set-Cookie"].split(";").first rescue nil
    end

  end
end
