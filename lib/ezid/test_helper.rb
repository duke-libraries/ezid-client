require "ezid-client"

module Ezid
  module TestHelper

    TEST_ARK_SHOULDER = "ark:/99999/fk4"
    TEST_DOI_SHOULDER = "doi:10.5072/FK2"

    TEST_USER = "apitest"
    TEST_HOST = Configuration::HOST
    TEST_PORT = Configuration::PORT
    TEST_SHOULDER = TEST_ARK_SHOULDER

    def ezid_test_mode!
      Ezid::Client.configure do |config|
        config.user     = ENV["EZID_TEST_USER"] || TEST_USER
        config.password = ENV["EZID_TEST_PASSWORD"]
        config.host     = ENV["EZID_TEST_HOST"] || TEST_HOST
        config.port     = ENV["EZID_TEST_PORT"] || TEST_PORT
        config.logger   = Logger.new(File::NULL)
        config.default_shoulder = ENV["EZID_TEST_SHOULDER"] || TEST_SHOULDER
      end
    end

  end
end

include Ezid::TestHelper
