require 'delegate'
require 'uri'
require 'net/http'
require 'forwardable'
require 'date'

require_relative '../responses/response'

module Ezid
  #
  # A request to the EZID service.
  #
  # @api private
  # @abstract
  #
  class Request < SimpleDelegator
    extend Forwardable

    # HTTP methods
    GET = Net::HTTP::Get
    PUT = Net::HTTP::Put
    POST = Net::HTTP::Post
    DELETE = Net::HTTP::Delete

    class << self
      attr_accessor :http_method, :path, :response_class

      def execute(client, *args)
        request = new(client, *args)
        yield request if block_given?
        request.execute
      end

      def short_name
        name.split('::').last.sub('Request', '')
      end
    end

    attr_reader :client
    def_delegators :client, :connection, :user, :password, :session

    # @param client [Ezid::Client] the client
    def initialize(client, *args)
      @client = client
      super build_request
      set_content_type('text/plain', charset: 'UTF-8')
    end

    # Executes the request and returns the response
    # @return [Ezid::Response] the response
    def execute
      retries = 0
      begin
        response_class.new(get_response_for_request)
      rescue Net::HTTPServerException, UnexpectedResponseError => e
        if retries < 2
          sleep 15
          retries += 1
          retry
        else
          raise
        end
      end
    end

    # The request URI
    # @return [URI] the URI
    def uri
      @uri ||= build_uri
    end

    # HTTP request path
    # @return [String] the path
    def path
      self.class.path
    end

    # Class to wrap Net::HTTPResponse
    # @return [Class]
    def response_class
      self.class.response_class || Response
    end

    # HTTP request query string
    # @return [String] the query string
    def query; end

    def authentication_required?
      true
    end

    def has_metadata?
      !metadata.empty? rescue false
    end

    def handle_response(http_response)
      response_class.new(http_response).tap do |response|
        yield response if block_given?
      end
    end

    private

    def get_response_for_request
      connection.start do |conn|
        self['Accept'] = 'text/plain'
        add_authentication if authentication_required?
        add_metadata if has_metadata?
        conn.request(__getobj__)
      end
    end

    def build_request
      self.class.http_method.new(uri)
    end

    def host
      connection.address
    end

    def build_uri
      uri_klass = connection.use_ssl? ? URI::HTTPS : URI::HTTP
      uri_klass.build(host: host, path: path, query: query)
    end

    # Adds authentication data to the request
    def add_authentication
      if session.open?
        self['Cookie'] = session.cookie
      else
        basic_auth(user, password)
      end
    end

    def add_metadata
      self.body = metadata.to_anvl(false)
    end

  end
end
