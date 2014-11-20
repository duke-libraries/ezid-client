module Ezid
  module TestHelper
    
    TEST_USER = "apitest"
    ARK_SHOULDER = "ark:/99999/fk4"
    DOI_SHOULDER = "doi:10.5072/FK2"

    def doi_metadata
      Metadata.new("datacite.title" => "Test", 
                   "datacite.creator" => "Duke",
                   "datacite.publisher" => "Duke",
                   "datacite.publicationyear" => "2014",
                   "datacite.resourcetype" => "Other")
    end

  end
end
