require "delegate"
require "uri"
require "forwardable"

module Ezid
  #
  # A request to the EZID service.
  #
  # @api private
  #
  class Request < SimpleDelegator
    extend Forwardable

    CHARSET = "UTF-8"
    CONTENT_TYPE = "text/plain"

    class << self
      attr_accessor :http_method

      def execute(client, *args)
        request = new(client, *args)
        yield request if block_given?
        request.execute
      end

      def short_name
        name.split("::").last.sub("Request", "")
      end
    end

    attr_reader :client
    def_delegators :client, :connection, :user, :password, :session

    # @param client [Ezid::Client] the client
    def initialize(client, *args)
      @client = client
      handle_args(*args)
      super build_request
    end

    # Executes the request and returns the response
    # @return [Ezid::Response] the response
    def execute
      http_response = connection.start do |conn| 
        set_content_type(CONTENT_TYPE, charset: CHARSET)
        add_authentication if authentication_required?
        add_metadata if accepts_metadata?
        conn.request(__getobj__) 
      end
      handle_response(http_response)
    end

    # The request URI
    # @return [URI] the URI
    def uri
      @uri ||= build_uri
    end

    # HTTP request path
    # @return [String] the path
    def path
      raise NotImplementedError, "Subclasses must implement `#path'."
    end

    # HTTP request query string
    # @return [String] the query string
    def query; end

    def authentication_required?
      true
    end

    def accepts_metadata?
      respond_to?(:metadata)
    end

    protected

    def handle_response(http_response)
      Response.new(http_response).tap do |response|
        yield response if block_given?
      end
    end

    # Subclass hook
    def handle_args(*args); end

    private

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
        self["Cookie"] = session.cookie
      else
        basic_auth(user, password)
      end
    end

    def add_metadata
      self.body = metadata.to_anvl(false) unless metadata.empty?
    end

  end
end
