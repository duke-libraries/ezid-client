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
    before { subject.instance_variable_set(:@elements, elements) }
    describe "#status" do
      it "should return the status" do
        expect(subject.status).to eq("public")
      end
    end
    describe "#target" do
      it "should return the target URL" do
        expect(subject.target).to eq("http://ezid.cdlib.org/id/ark:/99999/fk4fn19h87")
      end
    end
    describe "#profile" do
      it "should return the profile" do
        expect(subject.profile).to eq("erc")
      end
    end
    describe "#created" do
      it "should return the creation time" do
        expect(subject.created).to be_a(Time)
      end
    end
    describe "#updated" do
      it "should return the last update time" do
        expect(subject.updated).to be_a(Time)
      end
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
          subject.each_key { |k| subject[k] = subject[k].force_encoding("US_ASCII") }
        end
      end
      it "should be encoded in UTF-8" do
        expect(subject.to_anvl.encoding).to eq(Encoding::UTF_8)
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
          expect(subject.elements).to eq({"_updated" => "1416507086",
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
          expect(subject.elements).to eq({"_updated" => "1416507086",
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

  end
end
