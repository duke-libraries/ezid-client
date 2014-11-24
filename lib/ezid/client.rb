require_relative "api"
require_relative "request"
require_relative "response"
require_relative "metadata"
require_relative "session"
require_relative "configuration"
require_relative "error"
require_relative "logger"

module Ezid
  #
  # EZID client
  #
  # @api public
  class Client

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

      # Creates an new identifier
      # @see #create_identifier
      def create_identifier(*args)
        Client.new.create_identifier(*args)
      end

      # Mints a new identifier
      # @see #mint_identifier
      def mint_identifier(*args)
        Client.new.mint_identifier(*args)
      end
      
      # Retrieve the metadata for an identifier
      # @see #get_identifier_metadata
      def get_identifier_metadata(*args)
        Client.new.get_identifier_metadata(*args)
      end

      # Logs into EZID
      # @see #login
      def login
        Client.new.login
      end
    end    

    attr_reader :session, :user, :password

    def initialize(opts = {})
      @session = Session.new
      @user = opts[:user] || config.user
      @password = opts[:password] || config.password
      if block_given?
        login
        yield self
        logout
      end
    end

    def inspect
      out = super
      out.sub!(/@password="[^\"]+"/, "@password=\"********\"")
      out.sub!(/@session=#<[^>]+>/, logged_in? ? "LOGGED_IN" : "")
      out
    end

    # The client configuration
    # @return [Ezid::Configuration] the configuration object
    def config
      self.class.config
    end

    # The client logger
    # @return [Ezid::Logger] the logger
    def logger
      @logger ||= Ezid::Logger.new(config.logger)
    end

    # Open a session
    # @return [Ezid::Client] the client
    def login
      if logged_in?
        logger.info("Already logged in, skipping login request.")
      else
        do_login
      end
      self
    end

    # Close the session
    # @return [Ezid::Client] the client
    def logout
      if logged_in?
        do_logout
      else
        logger.info("Not logged in, skipping logout request.")
      end
      self
    end

    # @return [true, false] whether the client is logged in
    def logged_in?
      session.open?
    end

    # @param identifier [String] the identifier string to create
    # @param metadata [String, Hash, Ezid::Metadata] optional metadata to set
    # @return [Ezid::Response] the response
    def create_identifier(identifier, metadata=nil)
      request = Request.new(:create_identifier, identifier)
      add_authentication(request)
      add_metadata(request, metadata)
      execute(request)
    end

    # @param shoulder [String] the shoulder on which to mint a new identifier
    # @param metadata [String, Hash, Ezid::Metadata] metadata to set
    # @return [Ezid::Response] the response
    def mint_identifier(shoulder, metadata=nil)
      request = Request.new(:mint_identifier, shoulder)
      add_authentication(request)
      add_metadata(request, metadata)
      execute(request)
    end
    
    # @param identifier [String] the identifier to modify
    # @param metadata [String, Hash, Ezid::Metadata] metadata to set
    # @return [Ezid::Response] the response
    def modify_identifier(identifier, metadata)
      request = Request.new(:modify_identifier, identifier)
      add_authentication(request)
      add_metadata(request, metadata)
      execute(request)
    end

    # @param identifier [String] the identifier to retrieve
    # @return [Ezid::Response] the response
    def get_identifier_metadata(identifier)
      request = Request.new(:get_identifier_metadata, identifier)
      add_authentication(request)
      execute(request)
    end

    # @param identifier [String] the identifier to delete
    # @return [Ezid::Response] the response
    def delete_identifier(identifier)
      request = Request.new(:delete_identifier, identifier)
      add_authentication(request)
      execute(request)
    end

    # @param subsystems [Array]
    # @return [Ezid::Response] the response
    def server_status(*subsystems)
      request = Request.new(:server_status, *subsystems)
      execute(request)
    end

    private

    def build_request(*args)
      request = Request.new(*args)
    end

    # Executes the request
    # @param request [Ezid::Request] the request
    # @raise [Ezid::Error] if the response status indicates an error
    # @return [Ezid::Response] the response
    def execute(request)
      response = Response.new(request.execute)
      logger.request_and_response(request, response)
      raise Error, response.message if response.error?
      response
    end

    # Adds metadata to the request
    def add_metadata(request, metadata)
      return if metadata.nil? || metadata.empty?
      metadata = Metadata.new(metadata) # copy/coerce
      request.add_metadata(metadata) 
    end

    # Adds authentication to the request
    def add_authentication(request)
      if session.open?
        request.add_authentication(cookie: session.cookie)
      else
        request.add_authentication(user: user, password: password)
      end
    end

    # Does the login
    def do_login
      request = Request.new(:login)
      add_authentication(request)
      response = execute(request)
      session.open(response)
    end

    # Does the logoug
    def do_logout
      request = Request.new(:logout)
      execute(request)
      session.close
    end

  end
end
