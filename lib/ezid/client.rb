require "net/http"

require_relative "error"
require_relative "status"
require_relative "configuration"
require_relative "session"
require_relative "metadata"
require_relative "identifier"
require_relative "proxy_identifier"
require_relative "batch_download"

Dir[File.expand_path("../responses/*.rb", __FILE__)].each { |m| require m }
Dir[File.expand_path("../requests/*.rb", __FILE__)].each { |m| require m }

module Ezid
  #
  # EZID client
  #
  # @api public
  #
  class Client

    # ezid-client gem version (e.g., "0.8.0")
    VERSION = File.read(File.expand_path("../../../VERSION", __FILE__)).chomp.freeze

    # EZID API version
    API_VERSION = "2".freeze

    class << self
      # Configuration reader
      def config
        @config ||= Configuration.new
      end

      # Yields the configuration to a block
      # @yieldparam [Ezid::Configuration] the configuration
      def configure
        yield config
      end

      # Verbose version string
      # @return [String] the version
      def version
        "ezid-client #{VERSION} (EZID API Version #{API_VERSION})"
      end
    end

    attr_reader :user, :password, :host, :port, :use_ssl, :timeout

    def initialize(opts = {})
      @host = opts[:host] || config.host
      @port = (opts[:port] || config.port).to_i
      @use_ssl = opts[:use_ssl] || config.use_ssl
      @timeout = (opts[:timeout] || config.timeout).to_i
      @user = opts[:user] || config.user
      @password = opts[:password] || config.password
      if block_given?
        login
        yield self
        logout
      end
    end

    def inspect
      "#<#{self.class.name} connection=#{connection.inspect}, " \
        "user=#{user.inspect}, session=#{logged_in? ? 'OPEN' : 'CLOSED'}>"
    end

    # The client configuration
    # @return [Ezid::Configuration] the configuration object
    def config
      self.class.config
    end

    # The client logger
    # @return [Logger] the logger
    def logger
      @logger ||= config.logger
    end

    # The client session
    # @return [Ezid::Session] the session
    def session
      @session ||= Session.new
    end

    # Open a session
    # @raise [Ezid::Error]
    # @return [Ezid::Client] the client
    def login
      if logged_in?
        logger.info("Already logged in, skipping login request.")
      else
        response = execute LoginRequest
        session.open(response.cookie)
      end
      self
    end

    # Close the session
    # @return [Ezid::Client] the client
    def logout
      if logged_in?
        execute LogoutRequest
        session.close
      else
        logger.info("Not logged in, skipping logout request.")
      end
      self
    end

    # @return [true, false] whether the client is logged in
    def logged_in?
      session.open?
    end

    # Create an identifier (PUT an existing identifier)
    # @see http://ezid.cdlib.org/doc/apidoc.html#operation-create-identifier
    # @param identifier [String] the identifier string to create
    # @param metadata [String, Hash, Ezid::Metadata] optional metadata to set
    # @raise [Ezid::Error]
    # @return [Ezid::Response] the response
    def create_identifier(identifier, metadata=nil)
      execute CreateIdentifierRequest, identifier, metadata
    end

    # Mint an identifier
    # @see http://ezid.cdlib.org/doc/apidoc.html#operation-mint-identifier
    # @param shoulder [String] the shoulder on which to mint a new identifier
    # @param metadata [String, Hash, Ezid::Metadata] metadata to set
    # @raise [Ezid::Error]
    # @return [Ezid::Response] the response
    def mint_identifier(shoulder=nil, metadata=nil)
      shoulder ||= config.default_shoulder
      raise Error, "Shoulder missing -- cannot mint identifier." unless shoulder
      execute MintIdentifierRequest, shoulder, metadata
    end

    # Modify an identifier
    # @see http://ezid.cdlib.org/doc/apidoc.html#operation-modify-identifier
    # @param identifier [String] the identifier to modify
    # @param metadata [String, Hash, Ezid::Metadata] metadata to set
    # @raise [Ezid::Error]
    # @return [Ezid::Response] the response
    def modify_identifier(identifier, metadata)
      execute ModifyIdentifierRequest, identifier, metadata
    end

    # Get the metadata for an identifier
    # @see http://ezid.cdlib.org/doc/apidoc.html#operation-get-identifier-metadata
    # @param identifier [String] the identifier to retrieve
    # @raise [Ezid::Error]
    # @return [Ezid::Response] the response
    def get_identifier_metadata(identifier)
      execute GetIdentifierMetadataRequest, identifier
    end

    # Delete an identifier (only reserved identifier can be deleted)
    # @see http://ezid.cdlib.org/doc/apidoc.html#operation-delete-identifier
    # @param identifier [String] the identifier to delete
    # @raise [Ezid::Error]
    # @return [Ezid::Response] the response
    def delete_identifier(identifier)
      execute DeleteIdentifierRequest, identifier
    end

    # Get the EZID server status (and the status of one or more subsystems)
    # @see http://ezid.cdlib.org/doc/apidoc.html#server-status
    # @param subsystems [Array]
    # @raise [Ezid::Error]
    # @return [Ezid::StatusResponse] the status response
    def server_status(*subsystems)
      execute ServerStatusRequest, *subsystems
    end

    # Submit a batch download request
    # @see http://ezid.cdlib.org/doc/apidoc.html#batch-download
    # @param format [String] format of results - one of "anvl", "csv", "xml"
    # @param params [Hash] optional request parameters
    def batch_download(params={})
      execute BatchDownloadRequest, params
    end

    # The Net::HTTP object used to connect to EZID
    # @return [Net::HTTP] the connection
    def connection
      @connection ||= build_connection
    end

    private

    def use_ssl?
      use_ssl || port == 443
    end

    def build_connection
      conn = Net::HTTP.new(host, port)
      conn.use_ssl = use_ssl?
      conn.read_timeout = timeout
      conn
    end

    def handle_response(response, request_name)
      log_level = response.error? ? Logger::ERROR : Logger::INFO
      message = "EZID #{request_name} -- #{response.status_line}"
      logger.log(log_level, message)
      raise response.exception if response.exception
      response
    end

    def execute(request_class, *args)
      response = request_class.execute(self, *args)
      handle_response(response, request_class.short_name)
    end

  end
end
