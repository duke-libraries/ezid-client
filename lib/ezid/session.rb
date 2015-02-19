module Ezid
  #
  # An EZID session
  #
  # @api private
  #
  class Session

    attr_reader :cookie

    def initialize(cookie=nil)
      open(cookie) if cookie
    end

    def inspect
      super.sub(/@cookie="[^\"]+"/, "OPEN")
    end

    def open(cookie)
      @cookie = cookie
    end

    def close
      @cookie = nil
    end

    def closed?
      cookie.nil?
    end

    def open?
      !closed?
    end

  end
end
