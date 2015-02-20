require_relative "request"

module Ezid
  class BatchDownloadRequest < Request

    self.http_method = POST
    self.path = "/download_request"
    self.response_class = BatchDownloadResponse

    attr_reader :params

    def initialize(client, params={})
      @params = params
      super
    end

    def customize_request
      set_form_data(params)
    end

  end
end
