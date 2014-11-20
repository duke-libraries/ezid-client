require "logger"

module Ezid
  class Configuration

    attr_writer :user, :password, :logger
    attr_accessor :metadata_profile, :default_status

    def user
      @user ||= ENV["EZID_USER"]
    end

    def password
      @password ||= ENV["EZID_PASSWORD"]
    end

    def logger
      @logger ||= Logger.new(STDERR)
    end

  end
end
