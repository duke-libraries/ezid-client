require_relative "api"
require_relative "identifier"
require_relative "request"
require_relative "response"
require_relative "metadata"
require_relative "session"
require_relative "configuration"
require_relative "error"

module Ezid
  class Client

    class << self
      def config
        @config ||= Configuration.new
      end

      def configure
        yield config
      end

      def create_identifier(*args)
        Client.new.create_identifier(*args)
      end

      def mint_identifier(*args)
        Client.new.mint_identifier(*args)
      end

      def get_identifier_metadata(*args)
        Client.new.get_identifier_metadata(*args)
      end

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

    def config
      self.class.config
    end

    def logger
      config.logger
    end

    def login
      if logged_in?
        logger.info("Already logged in, skipping login request.")
      else
        do_login
      end
    end

    def logout
      if logged_in?
        do_logout
      else
        logger.info("Not logged in, skipping logout request.")
      end
    end

    def logged_in?
      session.open?
    end

    def create_identifier(identifier, metadata=nil)
      request = Request.build(:create_identifier, identifier)
      add_authentication(request)
      add_metadata(request, metadata)
      execute(request)
    end

    def mint_identifier(shoulder, metadata=nil)
      shoulder ||= config.default_shoulder
      request = Request.build(:mint_identifier, shoulder)
      add_authentication(request)
      add_metadata(request, metadata)
      execute(request)
    end
    
    def modify_identifier(identifier, metadata)
      request = Request.build(:modify_identifier, identifier)
      add_authentication(request)
      add_metadata(request, metadata)
      execute(request)
    end

    def get_identifier_metadata(identifier)
      request = Request.build(:get_identifier_metadata, identifier)
      add_authentication(request)
      execute(request)
    end

    def delete_identifier(identifier)
      request = Request.build(:delete_identifier, identifier)
      add_authentication(request)
      execute(request)
    end

    def server_status(*subsystems)
      request = Request.build(:server_status, subsystems)
      execute(request)
    end

    private

    # Executes the request
    def execute(request)
      response = request.execute
      handle_response(response)
    end

    # Handles the response
    def handle_response(response)
      raise Error, response.message if response.error?
      response
    ensure
      log_response(response)
    end

    # Logs a message for the response
    def log_response(response)
      logger.log(log_level(response), log_message(response))
    end

    # Returns the log level to use for the response
    def log_level(response)
      response.error? ? Logger::ERROR : Logger::INFO
    end

    # Returns the message to log for the response
    def log_message(response)
      response.status_line
    end

    # Adds metadata to the request
    def add_metadata(request, metadata, opts={})
      metadata = Metadata.new(metadata) # copy/coerce
      metadata.remove_readonly_elements!
      metadata.profile = client.default_metadata_profile if opts[:set_profile] && client.default_metadata_profile
      request.body = metadata.to_anvl unless metadata.empty?
    end

    # Adds authentication to the request
    def add_authentication(request)
      if session.open?
        request["Cookie"] = session.cookie 
      else
        request.basic_auth(user, password)
      end
    end

    def do_login
      request = Request.build(:login)
      add_authentication(request)
      response = execute(request)
      session.open(response)
      self
    end

    def do_logout
      request = Request.build(:logout)
      execute(request)
      session.close
      self
    end

  end
end
