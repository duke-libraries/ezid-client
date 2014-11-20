require "delegate"

module Ezid
  # A response from the EZID service.
  class Response < SimpleDelegator

    SUCCESS = "success"
    ERROR = "error"

    def self.build(http_response)
      Response.new(http_response)
    end

    def status
      @status ||= status_line.split(/: /)
    end

    def status_line
      content.first
    end

    def content
      @content ||= body.split(/\r?\n/, 2)
    end

    def metadata
      content.last if success? && identifier_uri?
    end

    def identifier
      message.split(/\s/).first if success? && identifier_uri?
    end

    def identifier_uri?
      uri.path =~ /^\/(id|shoulder)\//
    end

    def outcome
      status.first
    end

    def message
      status.last
    end

    def cookie
      self["Set-Cookie"].split(";").first rescue nil
    end

    def error?
      outcome == ERROR
    end

    def success?
      outcome == SUCCESS
    end

  end
end
