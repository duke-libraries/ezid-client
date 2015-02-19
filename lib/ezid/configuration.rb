require "logger"

module Ezid
  #
  # EZID client configuration.
  #
  # Use `Ezid::Client.configure` to set values.
  #
  # @api private
  #
  class Configuration

    HOST = "ezid.cdlib.org"
    PORT = 443

    # EZID host name
    #   Default: value of `EZID_HOST` environment variable, if present, or
    #   the EZID service host "ezid.cdlib.org".
    attr_accessor :host

    # EZID TCP/IP port
    #   Default: value of `EZID_PORT` variable
    attr_accessor :port

    # Use HTTPS?
    #   Default: `nil`; `true` if `EZID_USE_SSL` environment variable is set
    #   to the string "true".
    attr_accessor :use_ssl

    # EZID user name
    #   Default: value of `EZID_USER` environment variable
    attr_accessor :user

    # EZID password
    #   Default: value of `EZID_PASSWORD` environment variable
    attr_accessor :password

    # Ruby logger instance
    #   Default device: STDERR
    attr_writer :logger

    # Default shoulder for minting (scheme + NAAN + shoulder)
    # @example "ark:/99999/fk4"
    attr_accessor :default_shoulder

    def initialize
      @user             = ENV["EZID_USER"]
      @password         = ENV["EZID_PASSWORD"]
      @host             = ENV["EZID_HOST"] || HOST
      @port             = ENV["EZID_PORT"] || PORT
      @use_ssl          = true if ENV["EZID_USE_SSL"] == true.to_s
      @default_shoulder = ENV["EZID_DEFAULT_SHOULDER"]
    end

    def logger
      @logger ||= Logger.new(STDERR)
    end

    def identifier
      Identifier
    end

    def metadata
      Metadata
    end

  end
end
