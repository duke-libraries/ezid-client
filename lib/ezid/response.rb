require "delegate"

module Ezid
  #
  # A response from the EZID service.
  #
  # @note A Response should only be created by an Ezid::Client instance.
  # @api private
  class Response < SimpleDelegator

    # Success response status
    SUCCESS = "success"

    # Error response status
    ERROR = "error"

    # The response status -- "success" or "error"
    # @return [String] the status
    def status
      @status ||= status_line.split(/: /)
    end

    # The status line of the response
    # @return [String] the status line
    def status_line
      content.first
    end

    # The body of the response split into: status line and rest of body
    # @return [Array] status line, rest of body
    def content
      @content ||= body.split(/\r?\n/, 2)
    end

    # Metadata (if any) parsed out of the response
    # @return [Ezid::Metadata] the metadata
    def metadata
      return @metadata if @metadata
      if success? && identifier_uri?
        @metadata = Metadata.new(content.last) 
      end
      @metadata
    end

    # The identifier string parsed out of the response
    # @return [String] the identifier
    def identifier
      message.split(/\s/).first if success? && identifier_uri?
    end

    def identifier_uri?
      ( uri.path =~ /^\/(id|shoulder)\// ) && true
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
