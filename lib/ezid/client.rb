require_relative "configuration"
require_relative "request"
require_relative "response"
require_relative "session"
require_relative "metadata"
require_relative "identifier"
require_relative "error"
require_relative "status"

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
    end    

    attr_reader :session, :user, :password # , :host

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
      "#<#{self.class.name} user=\"#{user}\" session=#{logged_in? ? 'OPEN' : 'CLOSED'}>"
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

    # Open a session
    # @raise [Ezid::Error]
    # @return [Ezid::Client] the client
    def login
      if logged_in?
        logger.info("Already logged in, skipping login request.")
      else
        response = Request.execute(:Get, "/login") do |request|
          add_authentication(request)
        end
        handle_response(response, "LOGIN")
        session.open(response.cookie)
      end
      self
    end

    # Close the session
    # @return [Ezid::Client] the client
    def logout
      if logged_in?
        response = Request.execute(:Get, "/logout")
        handle_response(response, "LOGOUT")
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

    # @param identifier [String] the identifier string to create
    # @param metadata [String, Hash, Ezid::Metadata] optional metadata to set
    # @raise [Ezid::Error]
    # @return [Ezid::Response] the response
    def create_identifier(identifier, metadata=nil)
      response = Request.execute(:Put, "/id/#{identifier}") do |request|
        add_authentication(request)
        add_metadata(request, metadata)
      end
      handle_response(response, "CREATE #{identifier}")
    end

    # @param shoulder [String] the shoulder on which to mint a new identifier
    # @param metadata [String, Hash, Ezid::Metadata] metadata to set
    # @raise [Ezid::Error]
    # @return [Ezid::Response] the response
    def mint_identifier(shoulder, metadata=nil)
      raise Error, "Shoulder missing -- cannot mint identifier." unless shoulder
      response = Request.execute(:Post, "/shoulder/#{shoulder}") do |request|
        add_authentication(request)
        add_metadata(request, metadata)
      end
      handle_response(response, "MINT #{shoulder}")
    end
    
    # @param identifier [String] the identifier to modify
    # @param metadata [String, Hash, Ezid::Metadata] metadata to set
    # @raise [Ezid::Error]
    # @return [Ezid::Response] the response
    def modify_identifier(identifier, metadata)
      response = Request.execute(:Post, "/id/#{identifier}") do |request|
        add_authentication(request)
        add_metadata(request, metadata)
      end
      handle_response(response, "MODIFY #{identifier}")
    end

    # @param identifier [String] the identifier to retrieve
    # @raise [Ezid::Error]
    # @return [Ezid::Response] the response
    def get_identifier_metadata(identifier)
      response = Request.execute(:Get, "/id/#{identifier}") do |request|
        add_authentication(request)
      end
      handle_response(response, "GET #{identifier}")
    end

    # @param identifier [String] the identifier to delete
    # @raise [Ezid::Error]
    # @return [Ezid::Response] the response
    def delete_identifier(identifier)
      response = Request.execute(:Delete, "/id/#{identifier}") do |request|
        add_authentication(request)
      end
      handle_response(response, "DELETE #{identifier}")
    end

    # @param subsystems [Array]
    # @raise [Ezid::Error]
    # @return [Ezid::Status] the status response
    def server_status(*subsystems)
      response = Request.execute(:Get, "/status?subsystems=#{subsystems.join(',')}")
      handle_response(Status.new(response), "STATUS")
    end

    private

      # Adds authentication data to the request
      def add_authentication(request)
        if session.open?
          request["Cookie"] = session.cookie
        else
          request.basic_auth(user, password)
        end
      end

      # Adds EZID metadata (if any) to the request body
      def add_metadata(request, metadata)
        return if metadata.nil? || metadata.empty?
        metadata = Metadata.new(metadata) unless metadata.is_a?(Metadata)
        request.body = metadata.to_anvl(false) 
      end

      def handle_response(response, request_info)
        log_level = response.error? ? Logger::ERROR : Logger::INFO
        message = "EZID #{request_info} -- #{response.status_line}"
        logger.log(log_level, message)
        raise response.exception if response.exception
        response
      end

  end
end
