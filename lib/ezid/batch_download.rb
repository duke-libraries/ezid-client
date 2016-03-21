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
      begin
        tries += 1
        download = Net::HTTP.get_response(download_uri)
        download.value
      rescue Net::HTTPServerException => e
        if download.is_a?(Net::HTTPNotFound)
          if tries < MAX_DOWNLOAD_TRIES
            print "Download file not yet available (attempt #{tries} of #{MAX_DOWNLOAD_TRIES})."
            puts " Trying again in #{DOWNLOAD_RETRY_INTERVAL} second(s) ..."
            sleep DOWNLOAD_RETRY_INTERVAL
            retry
          else
            raise BatchDownloadError,
                  "Maximum download attempts (#{MAX_DOWNLOAD_TRIES}) reached unsuccessfully."
          end
        else
          raise
        end
      else
        File.open(fullpath, "wb") do |f|
          f.write(download.body)
        end
        puts "File successfully download to #{fullpath}."
      end
    end

    private

    def download_uri
      URI(download_url)
    end

    def download_filename
      File.basename(download_uri.path)
    end

    def client
      Client.new
    end

  end
end
