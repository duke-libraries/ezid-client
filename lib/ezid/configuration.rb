require "logger"

module Ezid
  #
  # EZID client configuration.
  #
  # Use Ezid::Client.configure to set values.
  #
  # @api private
  class Configuration

    # EZID user name
    #   Default: value of EZID_USER environment variable
    attr_accessor :user

    # EZID password
    #   Default: value of EZID_PASSWORD environment variable
    attr_accessor :password

    # Ruby logger instance
    #   Default device: STDERR
    attr_writer :logger

    # Default metadata profile
    # attr_accessor :default_metadata_profile

    # Default status - set only if default should not "public" (EZID default)
    # attr_accessor :default_status

    # Default shoulder for minting
    # attr_accessor :default_shoulder

    # Hash of options to pass to Net::HTTP.start
    # attr_accessor :http_request_options

    def initialize
      @user = ENV["EZID_USER"]
      @password = ENV["EZID_PASSWORD"]
      # @http_request_options = default_http_request_options
    end

    def logger
      @logger ||= Logger.new(STDERR)
    end

    # def default_http_request_options
    #   { use_ssl: true }
    # end

  end
end
