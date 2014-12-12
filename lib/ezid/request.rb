require "delegate"
require "uri"
require "net/http"

module Ezid
  #
  # A request to the EZID service.
  #
  # @api private
  #
  class Request < SimpleDelegator

    CHARSET = "UTF-8"
    CONTENT_TYPE = "text/plain"

    def self.execute(*args)
      request = new(*args)
      yield request if block_given?
      request.execute
    end

    # @param method [Symbol] the Net::HTTP constant for the request method
    # @param uri [URI] the uri 
    def initialize(method, uri) # path)
      http_method = Net::HTTP.const_get(method)
      super(http_method.new(uri))
      set_content_type(CONTENT_TYPE, charset: CHARSET)
    end

    # Executes the request and returns the response
    # @return [Ezid::Response] the response
    def execute
      http_response = Net::HTTP.start(uri.host, use_ssl: use_ssl?) do |http|
        http.request(__getobj__)
      end
      Response.new(http_response)
    end

    def use_ssl?
      uri.is_a?(URI::HTTPS)
    end

  end
end
