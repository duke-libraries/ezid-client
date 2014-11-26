module Ezid
  module TestHelper

    ARK_SHOULDER = "ark:/99999/fk4"
    DOI_SHOULDER = "doi:10.5072/FK2"
    USER = "apitest"

    Client.configure do |config|
      config.user = USER
    end

    def doi_metadata
      <<-EOS
datacite.title: Test
datacite.creator: Duke
datacite.publisher: Duke
datacite.publicationyear: 2014
datacite.resourcetype: Other
EOS
    end

  end
end
