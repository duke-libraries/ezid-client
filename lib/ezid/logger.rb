require "delegate"
require "logger"

module Ezid
  #
  # Custom logger for EZID client 
  #
  # @api private
  class Logger < SimpleDelegator

    # Logs a message for an EZID request/response
    # @param request [Ezid::Request] the request
    # @param response [Ezid::Response] the response
    def request_and_response(request, response)
      level = response.error? ? ::Logger::ERROR : ::Logger::INFO
      response_message = response.status_line
      message = "EZID #{request_message(request)}: #{response_message}"
      log(level, message)
    end

    private

    def request_message(request)
      message = request.operation[0].to_s
      args = request.operation[1..-1]
      message << "(#{args.join(', ')})" if args.any?
      message
    end

  end
end
