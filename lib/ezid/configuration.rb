require "logger"

module Ezid
  #
  # EZID client configuration.
  #
  # Use Ezid::Client.configure to set values.
  #
  # @api private
  class Configuration

    HOST = "ezid.cdlib.org"

    # EZID host name
    #   Default: "ezid.cdlib.org"
    attr_accessor :host

    # Use HTTPS?
    #   Default: `true`
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

    # Default metadata profile - "erc" (EZID default), "dc", "datacite", or "crossref"
    # If set, new identifiers (created or minted) will set the "_profile" element to
    # this value.
    # attr_accessor :default_metadata_profile

    # Default status - "public" (EZID default), "reserved", or "unavailable"
    # If set, new identifiers (created or minted) will set the "_status" element to
    # this value.
    # attr_accessor :default_status

    # Default shoulder for minting (scheme + NAAN + shoulder)
    # @example "ark:/99999/fk4"
    attr_accessor :default_shoulder

    def initialize
      @user = ENV["EZID_USER"]
      @password = ENV["EZID_PASSWORD"]
      @host = ENV["EZID_HOST"] || HOST
      @use_ssl = ENV["EZID_USE_SSL"] != false.to_s
    end

    def logger
      @logger ||= Logger.new(STDERR)
    end

    def identifier
      Identifier
    end

  end
end
