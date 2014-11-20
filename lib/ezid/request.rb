require "uri"
require "net/http"
require "delegate"

require_relative "api"
require_relative "response"

module Ezid
  #
  # A request to the EZID service.
  #
  class Request < SimpleDelegator

    EZID_HOST = "ezid.cdlib.org"
    CHARSET = "UTF-8"
    CONTENT_TYPE = "text/plain"

    def self.build(op, *args)
      http_method, path, query = Api.send(op, *args)
      uri = URI::HTTPS.build(host: EZID_HOST, path: path, query: query)
      http_request = Net::HTTP.const_get(http_method).new(uri)
      Request.new(http_request)
    end

    def execute
      http_response = Net::HTTP.start(uri.host, use_ssl: true) do |http|
        set_content_type(CONTENT_TYPE, charset: CHARSET)
        http.request(__getobj__)
      end
      Response.build(http_response)
    end

  end
end
