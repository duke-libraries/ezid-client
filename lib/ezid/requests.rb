require "net/http"
require_relative "request2"
require_relative "metadata"

module Ezid
  module Requests

    GET = Net::HTTP::Get
    PUT = Net::HTTP::Put
    POST = Net::HTTP::Post
    DELETE = Net::HTTP::Delete

    class LoginRequest < Request2
      self.http_method = GET

      def path
        "/login"
      end

      def handle_response(http_response)
        super do |response|
          session.open(response.cookie)
        end
      end
    end

    class LogoutRequest < Request2
      self.http_method = GET

      def path
        "/logout"
      end

      def authentication_required?
        false
      end

      def handle_response(http_response)
        super do |response|
          session.close          
        end
      end
    end

    class ServerStatusRequest < Request2
      self.http_method = GET
      attr_reader :subsystems

      def path 
        "/status"
      end

      def query
        "subsystems=#{subsystems.join(',')}"
      end

      def post_initialize(*args)
        @subsystems = args
      end

      def handle_response(http_response)
        Status.new(super)
      end
    end

    class MintIdentifierRequest < Request2
      self.http_method = POST
      attr_reader :shoulder, :metadata

      def post_initialize(*args)
        @shoulder = args.first
        @metadata = Metadata.new(args[1])
      end

      def path
        "/shoulder/#{shoulder}"
      end
    end

    class IdentifierRequest < Request2
      attr_reader :identifier

      def path
        "/id/#{identifier}"
      end

      def post_initialize(*args)
        @identifier = args.first
      end
    end

    class IdentifierWithMetadataRequest < IdentifierRequest
      attr_reader :metadata

      def post_initialize(*args)
        super
        @metadata = Metadata.new(args[1])
      end
    end

    class CreateIdentifierRequest < IdentifierWithMetadataRequest
      self.http_method = PUT
    end

    class ModifyIdentifierRequest < IdentifierWithMetadataRequest
      self.http_method = POST
    end

    class GetIdentifierMetadataRequest < IdentifierRequest
      self.http_method = GET
    end

    class DeleteIdentifierRequest < IdentifierRequest
      self.http_method = DELETE
    end

  end
end
