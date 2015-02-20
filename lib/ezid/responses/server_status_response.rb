require_relative "response"

module Ezid
  #
  # A response to an EZID status request
  # @api private
  #
  class ServerStatusResponse < Response

    SUBSYSTEMS = %w( noid ldap datacite )

    SUBSYSTEMS.each do |s|
      define_method(s) { subsystems[s] || "not checked" }
    end

    def subsystems
      return {} unless content[1]
      content[1].split(/\r?\n/).each_with_object({}) do |line, memo|
        subsystem, status = line.split(": ", 2)
        memo[subsystem] = status
      end
    end

    def up?
      success?
    end

  end
end
