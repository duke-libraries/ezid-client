require "delegate"
require "logger"

module Ezid
  #
  # Custom logger for EZID client 
  #
  # @api private
  class Logger < SimpleDelegator

    # Logs a message for an EZID response
    # @param response [Ezid::Response] the response
    def log_response(response)
      log(log_level(response), log_message(response))
    end

    # Returns the log level to use for an EZID response
    # @param response [Ezid::Response] the response
    def log_level(response)
      response.error? ? ::Logger::ERROR : ::Logger::INFO
    end

    # Returns the message to log for tan EZID response
    # @param response [Ezid::Response] the response
    def log_message(response)
      "[EZID] #{response.status_line}"
    end    

  end
end
