module Ezid
  #
  # EZID API Version 2 bindings
  #
  module Api

    VERSION = "2"

    # EZID server subsystems
    DATACITE_SUBSYSTEM = "datacite"
    NOID_SUBSYSTEM = "noid"
    LDAP_SUBSYSTEM = "ldap"
    ALL_SUBSYSTEMS = "*"

    class << self

      def login
        [:Get, "/login"]
      end

      def logout
        [:Get, "/logout"]
      end

      def mint_identifier(shoulder)
        [:Post, "/shoulder/#{shoulder}"]
      end

      def create_identifier(identifier)
        [:Put, "/id/#{identifier}"]
      end

      def modify_identifier(identifier)
        [:Post, "/id/#{identifier}"]
      end

      def get_identifier_metadata(identifier)
        [:Get, "/id/#{identifier}"]
      end

      def delete_identifier(identifier)
        [:Delete, "/id/#{identifier}"]
      end

      def server_status(subsystems)
        [:Get, "/status", "subsystems=#{subsystems.join(',')}"]
      end

    end

  end
end
