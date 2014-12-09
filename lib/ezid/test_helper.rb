require "ezid-client"

module Ezid
  module TestHelper

    TEST_ARK_SHOULDER = "ark:/99999/fk4"
    TEST_DOI_SHOULDER = "doi:10.5072/FK2"
    TEST_USER = "apitest"

    def ezid_test_mode!
      Ezid::Client.configure do |config|
        config.user = TEST_USER
        # Contact EZID for password
        # config.password = "********"
        config.logger = Logger.new(File::NULL)
        config.default_shoulder = TEST_ARK_SHOULDER
      end
    end

  end
end

include Ezid::TestHelper

