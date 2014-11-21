require "uri"
require "net/http"

module Ezid
  #
  # A request to the EZID service.
  #
  # @note A Request should only be created by an Ezid::Client instance.
  # @api private
  class Request

    EZID_HOST = "ezid.cdlib.org"
    CHARSET = "UTF-8"
    CONTENT_TYPE = "text/plain"

    attr_reader :http_request, :uri, :operation

    def initialize(*args)
      @operation = args
      http_method, path, query = Api.send(*args)
      @uri = URI::HTTPS.build(host: EZID_HOST, path: path, query: query)
      @http_request = Net::HTTP.const_get(http_method).new(uri)
      @http_request.set_content_type(CONTENT_TYPE, charset: CHARSET)
    end

    # Executes the request and returns the HTTP response
    # @return [Net::HTTPResponse] the response
    def execute
      Net::HTTP.start(uri.host, use_ssl: true) do |http|
        http.request(http_request)
      end
    end

    # Adds authentication data to the request
    # @param opts [Hash] the options.
    #   Must include either: `:cookie`, or: `:user` and `:password`.
    # @option opts [String] :cookie a session cookie
    # @option opts [String] :user user name for basic auth
    # @option opts [String] :password password for basic auth
    def add_authentication(opts={})
      if opts[:cookie]
        http_request["Cookie"] = opts[:cookie]
      else
        http_request.basic_auth(opts[:user], opts[:password])
      end
    end

    # Adds EZID metadata (if any) to the request body
    # @param metadata [Ezid::Metadata] the metadata to add
    def add_metadata(metadata)
      http_request.body = metadata.to_anvl unless metadata.empty?
    end

  end
end
