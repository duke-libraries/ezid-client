module Ezid
  RSpec.describe Metadata do
    
    let(:elements) do
        { "_updated" => "1416507086",
          "_target" => "http://ezid.cdlib.org/id/ark:/99999/fk4fn19h87",
          "_profile" => "erc",
          "_ownergroup" => "apitest",
          "_owner" => "apitest",
          "_export" => "yes",
          "_created" => "1416507086",
          "_status" => "public" }
    end
    subject { described_class.new(elements) }

    it "should have a non-leading-underscore reader for each reserved element, except '_crossref'" do
      Metadata::RESERVED_ELEMENTS.each do |element|
        next if element == "_crossref"
        expect(subject).to respond_to(element.sub("_", ""))
      end      
    end

    describe "element reader aliases for datetime elements" do
      it "should return Time values" do
        expect(subject.created).to eq Time.parse("2014-11-20 13:11:26 -0500")
        expect(subject.updated).to eq Time.parse("2014-11-20 13:11:26 -0500")
      end
    end

    it "should have a non-leading-underscore writer for each writable reserved element, except '_crossref'" do
      Metadata::RESERVED_READWRITE_ELEMENTS.each do |element|
        next if element == "_crossref"
        expect(subject).to respond_to("#{element.sub('_', '')}=")
      end      
    end    

    describe "#update" do
      it "should coerce the data"
      it "should update the delegated hash"
    end

    describe "#replace" do
      it "should coerce the data"
      it "should call `replace' on the delegated hash"
    end

    describe "ANVL output" do
      it "should output the proper format" do
        expect(subject.to_anvl).to eq("\
_updated: 1416507086
_target: http://ezid.cdlib.org/id/ark:/99999/fk4fn19h87
_profile: erc
_ownergroup: apitest
_owner: apitest
_export: yes
_created: 1416507086
_status: public")
      end
      describe "encoding" do
        before do
          subject.each_key { |k| subject[k] = subject[k].force_encoding(Encoding::US_ASCII) }
        end
        it "should be encoded in UTF-8" do
          expect(subject.to_anvl.encoding).to eq(Encoding::UTF_8)
        end
      end
      describe "escaping" do
        before do
          subject["_target"] = "http://example.com/path%20with%20spaces"
          subject["dc.title"] = "A really long title\nneeds a line feed"
          subject["dc.creator"] = "David Chandek-Stark\r\nJim Coble"
        end
        it "should escape a line feed" do
          expect(subject.to_anvl).to match(/dc.title: A really long title%0Aneeds a line feed/)
        end
        it "should escape a carriage return" do
          expect(subject.to_anvl).to match(/dc.creator: David Chandek-Stark%0D%0AJim Coble/)
        end
        it "should escape a percent sign" do
          expect(subject.to_anvl).to match(/_target: http:\/\/example.com\/path%2520with%2520spaces/)
        end
      end
    end

    describe "coercion" do
      subject { described_class.new(data) }
      context "of a string" do
        let(:data) do <<-EOS
_updated: 1416507086
_target: http://ezid.cdlib.org/id/ark:/99999/fk4fn19h87
_profile: erc
_ownergroup: apitest
_owner: apitest
_export: yes
_created: 1416507086
_status: public
EOS
        end
        it "should coerce the data into a hash" do
          expect(subject).to eq({"_updated" => "1416507086",
                                 "_target" => "http://ezid.cdlib.org/id/ark:/99999/fk4fn19h87",
                                 "_profile" => "erc",
                                 "_ownergroup" => "apitest",
                                 "_owner" => "apitest",
                                 "_export" => "yes",
                                 "_created" => "1416507086",
                                 "_status" => "public"})
        end
      end
      context "of a hash" do
        let(:data) do
          { _updated: "1416507086",
            _target: "http://ezid.cdlib.org/id/ark:/99999/fk4fn19h87",
            _profile: "erc",
            _ownergroup: "apitest",
            _owner: "apitest",
            _export: "yes",
            _created: "1416507086",
            _status: "public" }
        end
        it "should stringify the keys" do
          expect(subject).to eq({"_updated" => "1416507086",
                                  "_target" => "http://ezid.cdlib.org/id/ark:/99999/fk4fn19h87",
                                  "_profile" => "erc",
                                  "_ownergroup" => "apitest",
                                  "_owner" => "apitest",
                                  "_export" => "yes",
                                  "_created" => "1416507086",
                                  "_status" => "public"})
        end
      end
    end

    describe "profiles" do
      describe "dc" do
        describe "readers" do
          before do
            subject.update("dc.title" => "Testing Profiles",
                           "dc.creator" => "Kermit the Frog",
                           "dc.publisher" => "Duke University",
                           "dc.date" => "2004",
                           "dc.type" => "Text")
          end
          it "should have a reader for each element" do
            expect(subject.dc_title).to eq("Testing Profiles")
            expect(subject.dc_creator).to eq("Kermit the Frog")
            expect(subject.dc_publisher).to eq("Duke University")
            expect(subject.dc_date).to eq("2004")
            expect(subject.dc_type).to eq("Text")
          end
        end
        describe "writers" do
          before do
            subject.dc_title = "Run of the Mill"
            subject.dc_creator = "Jack Bean"
            subject.dc_publisher = "Random Housing"
            subject.dc_date = "1967"
            subject.dc_type = "Physical Object"
          end
          it "should have a writer for each element" do
            expect(subject["dc.title"]).to eq "Run of the Mill"
            expect(subject["dc.creator"]).to eq "Jack Bean"
            expect(subject["dc.publisher"]).to eq "Random Housing"
            expect(subject["dc.date"]).to eq "1967"
            expect(subject["dc.type"]).to eq "Physical Object"
          end
        end
      end
      describe "erc" do
        describe "readers" do
          before do
            subject.update("erc.what" => "Testing Profiles",
                            "erc.who" => "Kermit the Frog",
                            "erc.when" => "2004")
          end
          it "should have a reader for each element" do
            expect(subject.erc_what).to eq("Testing Profiles")
            expect(subject.erc_who).to eq("Kermit the Frog")
            expect(subject.erc_when).to eq("2004")
          end
        end
        describe "writers" do
          before do
            subject.erc_what = "Run of the Mill"
            subject.erc_who = "Jack Bean"
            subject.erc_when = "1967"
          end
          it "should have a writer for each element" do
            expect(subject["erc.what"]).to eq "Run of the Mill"
            expect(subject["erc.who"]).to eq "Jack Bean"
            expect(subject["erc.when"]).to eq "1967"
          end
        end
      end
      describe "crossref" do
        describe "xml document reader" do
          before do
            subject["crossref"] = "<xml/>" 
          end
          it "should return the xml" do
            expect(subject.crossref).to eq "<xml/>"
        end
      end
      describe "xml document writer" do
        before do
          subject.crossref = "<yml/>"
        end
        it "should set the 'crossref' metadata element" do
          expect(subject["crossref"]).to eq "<yml/>"
        end
      end
      end
      describe "datacite" do
        describe "element readers" do
          before do
            subject.update("datacite.title" => "Testing Profiles",
                           "datacite.creator" => "Kermit the Frog",
                           "datacite.publisher" => "Duke University",
                           "datacite.publicationyear" => "2004",
                           "datacite.resourcetype" => "Text")
          end
          it "should have a reader for each element" do
            expect(subject.datacite_title).to eq("Testing Profiles")
            expect(subject.datacite_creator).to eq("Kermit the Frog")
            expect(subject.datacite_publisher).to eq("Duke University")
            expect(subject.datacite_publicationyear).to eq("2004")
            expect(subject.datacite_resourcetype).to eq("Text")
          end
        end
        describe "element writers" do
          before do
            subject.datacite_title = "Run of the Mill"
            subject.datacite_creator = "Jack Bean"
            subject.datacite_publisher = "Random Housing"
            subject.datacite_publicationyear = "1967"
            subject.datacite_resourcetype = "Physical Object"
          end
          it "should have a writer for each element" do
            expect(subject["datacite.title"]).to eq "Run of the Mill"
            expect(subject["datacite.creator"]).to eq "Jack Bean"
            expect(subject["datacite.publisher"]).to eq "Random Housing"
            expect(subject["datacite.publicationyear"]).to eq "1967"
            expect(subject["datacite.resourcetype"]).to eq "Physical Object"
          end
        end
        describe "xml document reader" do
          before do
            subject["datacite"] = "<xml/>" 
          end
          it "should return the xml" do
            expect(subject.datacite).to eq "<xml/>"
          end
        end
        describe "xml document writer" do
          before do
            subject.datacite = "<yml/>"
          end
          it "should set the 'datacite' metadata element" do
            expect(subject["datacite"]).to eq "<yml/>"
          end
        end
      end
    end

  end
end
