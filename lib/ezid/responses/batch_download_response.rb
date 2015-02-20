require_relative "response"

module Ezid
  class BatchDownloadResponse < Response

    def download_url
      message
    end

  end
end
