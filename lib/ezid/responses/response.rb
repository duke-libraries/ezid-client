require "delegate"

module Ezid
  #
  # A response from the EZID service.
  #
  # @api private
  #
  class Response < SimpleDelegator

    # Success response status
    SUCCESS = "success".freeze

    # Error response status
    ERROR = "error".freeze

    def initialize(http_response)
      http_response.value # raises Net::HTTPServerException

      super

      unless status_line =~ /^(#{SUCCESS}|#{ERROR}): /
        raise UnexpectedResponseError, __getobj__.body
      end
    end

    # The response status -- "success" or "error"
    # @return [String] the status
    def status
      @status ||= status_line.split(/: /)
    end

    # The status line of the response
    # @return [String] the status line
    def status_line
      content[0]
    end

    # The body of the response split into: status line and rest of body
    # @return [Array] status line, rest of body
    def content
      @content ||= body.split(/\r?\n/, 2)
    end

    # The outcome of the request - "success" or "error"
    # @return [String] the outcome
    def outcome
      status.first
    end

    # The EZID status message
    # @return [String] the message
    def message
      status.last
    end

    # Whether the outcome was an error
    # @return [Boolean]
    def error?
      outcome == ERROR
    end

    # Whether the outcome was a success
    # @return [Boolean]
    def success?
      outcome == SUCCESS
    end

    # Returns an exception instance if there was an error
    # @return [Ezid::Error] the exception
    def exception
      error_class.new(message) if error?
    end

    # The URI path of the request
    # @return [String] the path
    def uri_path
      __getobj__.uri.path
    end

    def error_class
      case message
      when /no such identifier/
        IdentifierNotFoundError
      when /identifier status does not support deletion/
        DeletionError
      else
        Error
      end
    end

  end
end
