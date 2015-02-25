require_relative "request"

module Ezid
  class BatchDownloadRequest < Request

    self.http_method = POST
    self.path = "/download_request"
    self.response_class = BatchDownloadResponse

    def initialize(client, params={})
      super
      set_form_data(params)
    end

  end
end
