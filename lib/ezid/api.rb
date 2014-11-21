module Ezid
  #
  # EZID API Version 2 bindings
  #
  # @api private
  module Api

    VERSION = "2"

    # EZID server subsystems
    # "*" = all subsystems
    SUBSYSTEMS = %w( datacite noid ldap * )

    class << self
      
      # Start a session
      # @see http://ezid.cdlib.org/doc/apidoc.html#authentication
      def login
        [:Get, "/login"]
      end

      # End the current session
      # @see http://ezid.cdlib.org/doc/apidoc.html#authentication
      def logout
        [:Get, "/logout"]
      end

      # Operation: mint identifier
      # @see http://ezid.cdlib.org/doc/apidoc.html#operation-mint-identifier
      def mint_identifier(shoulder)
        [:Post, "/shoulder/#{shoulder}"]
      end

      # Operation: create identifier
      # @see http://ezid.cdlib.org/doc/apidoc.html#operation-create-identifier
      def create_identifier(identifier)
        [:Put, "/id/#{identifier}"]
      end

      # Operation: modify identifier
      # @see http://ezid.cdlib.org/doc/apidoc.html#operation-modify-identifier
      def modify_identifier(identifier)
        [:Post, "/id/#{identifier}"]
      end

      # Operation: get identifier metadata
      # @see http://ezid.cdlib.org/doc/apidoc.html#operation-get-identifier-metadata
      def get_identifier_metadata(identifier)
        [:Get, "/id/#{identifier}"]
      end

      # Operation: delete identifier
      # @see http://ezid.cdlib.org/doc/apidoc.html#operation-delete-identifier
      def delete_identifier(identifier)
        [:Delete, "/id/#{identifier}"]
      end

      # Probe EZID server status
      # @see http://ezid.cdlib.org/doc/apidoc.html#server-status
      def server_status(*subsystems)
        [:Get, "/status", "subsystems=#{subsystems.join(',')}"]
      end

    end

  end
end
