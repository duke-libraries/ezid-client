module Ezid
  RSpec.describe Metadata do

    describe "method missing" do
      context "for an internal element name w/o leading underscore" do
        it "should call the reader method" do
          expect(subject).to receive(:reader).with("_status")
          subject.status
        end
      end
      context "for an internal writable element name + '=' and w/o leading underscore" do
        it "should call the writer method" do
          expect(subject).to receive(:writer).with("_status", "public")
          subject.status = "public"
        end
      end
      context "for an internal readonly element name + '=' and w/o leading underscore" do
        it "should not call the writer method" do
          expect { subject.created = "1416507086" }.to raise_error
        end
      end
    end

    describe "internal element reader" do
      context "for a datetime element" do
        before { subject["_created"] = "1416507086" }
        it "should return a Time" do          
          expect(subject.created).to be_a(Time)
        end
      end
      context "for a non-datetime element" do
        before { subject["_status"] = "public" }
        it "should return the value" do
          expect(subject.status).to eq("public")
        end
      end
    end

    describe "internal element writer" do
      before { subject["_status"] = "reserved" }
      it "should set the element" do
        expect { subject.status = "public" }.to change { subject["_status"] }.from("reserved").to("public")
      end
    end

    describe "ANVL output" do
      let(:metadata) { described_class.new(_updated: "1416507086",
                                           _target: "http://ezid.cdlib.org/id/ark:/99999/fk4fn19h87",
                                           _profile: "erc",
                                           _ownergroup: "apitest",
                                           _owner: "apitest",
                                           _export: "yes",
                                           _created: "1416507086",
                                           _status: "public") }
      it "should output the proper format" do
        expect(metadata.to_anvl).to eq("\
_updated: 1416507086
_target: http://ezid.cdlib.org/id/ark:/99999/fk4fn19h87
_profile: erc
_ownergroup: apitest
_owner: apitest
_export: yes
_created: 1416507086
_status: public")
      end
      describe "escaping" do
        context "of element names" do
          it "should escape a colon"
          it "should escape a line feed"
          it "should escape a carriage return"
          it "should escape a percent sign"
        end
        context "of element values" do
          it "should escape a line feed"
          it "should escape a carriage return"
          it "should escape a percent sign"
        end
      end
    end

    describe "coercion" do
      context "of a string" do
        let(:data) { "\
_updated: 1416507086
_target: http://ezid.cdlib.org/id/ark:/99999/fk4fn19h87
_profile: erc
_ownergroup: apitest
_owner: apitest
_export: yes
_created: 1416507086
_status: public" }
        subject { described_class.new(data) }
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
        it "should stringify the keys"
      end
      context "of an Ezid::Metadata instance" do
        it "should return the elements hash"
      end
    end

  end
end
