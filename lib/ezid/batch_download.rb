require "hashie"
require "net/http"
require "uri"
require "date"

module Ezid
  class BatchDownloadError < Error; end

  class BatchDownload < Hashie::Dash
    include Hashie::Extensions::Coercion

    ANVL    = "anvl".freeze
    CSV     = "csv".freeze
    XML     = "xml".freeze
    FORMATS = [ ANVL, CSV, XML ].freeze

    YES      = "yes".freeze
    NO       = "no".freeze
    BOOLEANS = [ YES, NO ].freeze

    TEST       = "test".freeze
    REAL       = "real".freeze
    PERMANENCE = [ TEST, REAL ].freeze

    ARK     = "ark".freeze
    DOI     = "doi".freeze
    URN     = "urn".freeze
    TYPES   = [ ARK, DOI, URN, ].freeze

    # CSV Columns
    ID               = "_id".freeze
    MAPPED_CREATOR   = "_mappedCreator".freeze
    MAPPED_TITLE     = "_mappedTitle".freeze
    MAPPED_PUBLISHER = "_mappedPublisher".freeze
    MAPPED_DATE      = "_mappedDate".freeze
    MAPPED_TYPE      = "_mappedType".freeze

    MAX_DOWNLOAD_TRIES = 300
    DOWNLOAD_RETRY_INTERVAL = 1

    # Parameters
    property :format, required: true # {anvl|csv|xml}
    property :compression            # {gzip|zip}
    property :column                 # repeatable
    property :notify                 # repeatable
    property :convertTimestamps      # {yes|no}

    # Search constraints
    property :createdAfter
    property :createdBefore
    property :crossref   # {yes|no}
    property :exported   # {yes|no}
    property :owner      # repeatable
    property :ownergroup # repeatable
    property :permanence # {test|real}
    property :profile    # (repeatable)
    property :status     # {reserved|public|unavailable} (repeatable)
    property :type       # {ark|doi|urn} (repeatable)
    property :updatedAfter
    property :updatedBefore

    coerce_value FalseClass, ->(v) { NO }
    coerce_value TrueClass,  ->(v) { YES }
    coerce_value DateTime,   ->(v) { v.to_time.utc.iso8601 }
    coerce_value Time, Integer

    def initialize(format, args={})
      super(args.merge(format: format))
    end

    def params
      to_h
    end

    def get_response
      @response ||= client.batch_download(params)
    end

    def reload
      @response = nil
    end

    def download_url
      get_response.download_url
    end

    def download_file(path: nil)
      path ||= Dir.getwd
      fullpath = File.directory?(path) ? File.join(path, download_filename) : path
      tries = 0
      ready = false

      print "Checking for download "
      Net::HTTP.start(download_uri.host, download_uri.port) do |http|
        while tries < MAX_DOWNLOAD_TRIES
          tries += 1
          sleep DOWNLOAD_RETRY_INTERVAL
          print "."
          response = http.head(download_uri.path)
          if response.code == '200'
            ready = true
            break
          end
        end
      end
      puts

      unless ready
        raise BatchDownloadError,
              "Download not ready after checking #{MAX_DOWNLOAD_TRIES} times."
      end

      File.open(fullpath, "wb") do |f|
        Net::HTTP.start(download_uri.host, download_uri.port) do |http|
          http.request_get(download_uri.path) do |response|
            response.read_body do |chunk|
              f.write(chunk)
            end
          end
        end
      end

      fullpath
    end

    private

    def download_uri
      @download_uri ||= URI(download_url)
    end

    def download_filename
      File.basename(download_uri.path)
    end

    def client
      Client.new
    end

  end
end
