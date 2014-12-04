require "delegate"
require "uri"
require "net/http"

module Ezid
  #
  # A request to the EZID service.
  #
  # @api private
  class Request < SimpleDelegator

    HOST = "https://ezid.cdlib.org"
    CHARSET = "UTF-8"
    CONTENT_TYPE = "text/plain"

    def self.execute(*args)
      request = new(*args)
      yield request if block_given?
      request.execute
    end

    # @param method [Symbol] the Net::HTTP constant for the request method
    # @param path [String] the uri path (including query string, if any)
    def initialize(method, path)
      http_method = Net::HTTP.const_get(method)
      uri = URI.parse([HOST, path].join)
      super(http_method.new(uri))
      set_content_type(CONTENT_TYPE, charset: CHARSET)
    end

    # Executes the request and returns the response
    # @return [Ezid::Response] the response
    def execute
      http_response = Net::HTTP.start(uri.host, use_ssl: true) do |http|
        http.request(__getobj__)
      end
      Response.new(http_response)
    end

  end
end
