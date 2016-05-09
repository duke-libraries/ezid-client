require "active_model"
require "hydra/validations"
require "hashie"
require "net/http"
require "uri"
require "date"

module Ezid
  class BatchDownloadError < Error; end

  class BatchDownload < Hashie::Dash
    include Hashie::Extensions::Coercion
    include ActiveModel::Validations
    include Hydra::Validations

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
    coerce_value Date,       ->(v) { v.to_time.utc.iso8601 }
    coerce_value Time,       ->(v) { v.utc.iso8601 }
    coerce_value Symbol, String

    validates_inclusion_of :format, in: FORMATS
    validates_inclusion_of :permanence, in: PERMANENCE, allow_nil: true
    validates_inclusion_of :crossref, in: BOOLEANS, allow_nil: true
    validates_inclusion_of :exported, in: BOOLEANS, allow_nil: true
    validates_inclusion_of :convertTimestamps, in: BOOLEANS, allow_nil: true
    validates_inclusion_of :type, in: TYPES, allow_nil: true
    validates_inclusion_of :status,
                           in: [ Status::PUBLIC, Status::RESERVED, Status::UNAVAILABLE ],
                           allow_nil: true
    validates_inclusion_of :profile, in: Metadata::PROFILES, allow_nil: true
    validates_presence_of :column, if: :csv?

    def self.alias_property(ali, prop)
      alias_method ali, prop
      define_method "#{ali}=" do |value|
        send("#{prop}=", value)
      end
    end

    FORMATS.each do |fmt|
      define_method "#{fmt}?" do
        format == fmt
      end
    end

    alias_property :convert_timestamps, :convertTimestamps
    alias_property :created_after, :createdAfter
    alias_property :created_before, :createdBefore
    alias_property :updated_after, :updatedAfter
    alias_property :updated_before, :updatedBefore

    def initialize(format, args={})
      super(args.merge(format: format))
    end

    def convert_timestamps!
      self.convertTimestamps = true
    end

    def params
      to_h.reject { |k, v| v.nil? }
    end

    def get_response
      if @response.nil?
        raise Error, "Invalid batch download parameters:\n#{errors.to_a.join('\n')}" if invalid?
        @response = client.batch_download(params)
      end
      @response
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
            print "."
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
        puts "\nFile successfully downloaded to #{fullpath}."
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
