require "logger"

module Ezid
  #
  # EZID client configuration.
  #
  # Use Ezid::Client.configure to set values.
  #
  # @api private
  class Configuration

    attr_writer :user, :password, :logger

    # Default metadata profile (recommended)
    attr_accessor :default_metadata_profile

    # Default status - set only if default should not "public" (EZID default)
    attr_accessor :default_status

    # Default shoulder for minting (recommended)
    attr_accessor :default_shoulder

    def user
      @user ||= ENV["EZID_USER"]
    end

    def password
      @password ||= ENV["EZID_PASSWORD"]
    end

    def logger
      @logger ||= ::Logger.new(STDERR)
    end

  end
end
