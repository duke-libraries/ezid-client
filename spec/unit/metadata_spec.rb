module Ezid
  RSpec.describe Metadata do

    describe "metadata accessors and aliases" do
      shared_examples "a metadata writer" do |writer|
        it "writes the \"#{writer}\" element" do
          subject.send("#{writer}=", "value")
          expect(subject[writer.to_s]).to eq("value")
        end
      end

      shared_examples "a metadata reader" do |reader|
        it "reads the \"#{reader}\" element" do
          subject[reader.to_s] = "value"
          expect(subject.send(reader)).to eq("value")
        end
      end

      shared_examples "a metadata reader with an alias" do |reader, aliased_as|
        it_behaves_like "a metadata reader", reader
        it "has a reader alias \"#{aliased_as}\"" do
          subject[reader.to_s] = "value"
          expect(subject.send(aliased_as)).to eq("value")
        end
      end

      shared_examples "a metadata writer with an alias" do |writer, aliased_as|
        it_behaves_like "a metadata writer", writer
        it "has a writer alias \"#{aliased_as}\"" do
          subject.send("#{aliased_as}=", "value")
          expect(subject.send(writer)).to eq("value")
        end
      end

      shared_examples "a metadata accessor" do |accessor|
        it_behaves_like "a metadata reader", accessor
        it_behaves_like "a metadata writer", accessor
      end

      shared_examples "a metadata accessor with an alias" do |accessor, aliased_as|
        it_behaves_like "a metadata reader with an alias", accessor, aliased_as
        it_behaves_like "a metadata writer with an alias", accessor, aliased_as
      end

      shared_examples "a time reader alias" do |element, aliased_as|
        before { subject[element.to_s] = "1416507086" }
        it "should return the Time value for the element" do
          expect(subject.send(aliased_as)).to eq(Time.parse("2014-11-20 13:11:26 -0500"))
        end
      end

      shared_examples "a metadata profile accessor with an alias" do |profile, accessor|
        it_behaves_like "a metadata accessor with an alias", [profile, accessor].join("."), [profile, accessor].join("_")
      end

      describe "_owner" do
        it_behaves_like "a metadata reader with an alias", :_owner, :owner
      end
      describe "_ownergroup" do
        it_behaves_like "a metadata reader with an alias", :_ownergroup, :ownergroup
      end
      describe "_shadows" do
        it_behaves_like "a metadata reader with an alias", :_shadows, :shadows
      end
      describe "_shadowedby" do
        it_behaves_like "a metadata reader with an alias", :_shadowedby, :shadowedby
      end
      describe "_datacenter" do
        it_behaves_like "a metadata reader with an alias", :_datacenter, :datacenter
      end

      describe "_coowners" do
        it_behaves_like "a metadata accessor with an alias", :_coowners, :coowners
      end
      describe "_target" do
        it_behaves_like "a metadata accessor with an alias", :_target, :target
      end
      describe "_profile" do
        it_behaves_like "a metadata accessor with an alias", :_profile, :profile
      end
      describe "_status" do
        it_behaves_like "a metadata accessor with an alias", :_status, :status
      end
      describe "_export" do
        it_behaves_like "a metadata accessor with an alias", :_export, :export
      end

      describe "_created" do
        it_behaves_like "a metadata reader", :_created
        it_behaves_like "a time reader alias", :_created, :created
      end
      describe "_updated" do
        it_behaves_like "a metadata reader", :_updated
        it_behaves_like "a time reader alias", :_updated, :updated
      end

      describe "erc" do
        it_behaves_like "a metadata accessor", :erc
      end
      describe "datacite" do
        it_behaves_like "a metadata accessor", :datacite
      end
      describe "_crossref" do
        it_behaves_like "a metadata accessor", :_crossref
      end
      describe "crossref" do
        it_behaves_like "a metadata accessor", :crossref
      end

      describe "dc.creator" do
        it_behaves_like "a metadata profile accessor with an alias", :dc, :creator
      end
      describe "dc.title" do
        it_behaves_like "a metadata profile accessor with an alias", :dc, :title
      end
      describe "dc.publisher" do
        it_behaves_like "a metadata profile accessor with an alias", :dc, :publisher
      end
      describe "dc.date" do
        it_behaves_like "a metadata profile accessor with an alias", :dc, :date
      end
      describe "dc.type" do
        it_behaves_like "a metadata profile accessor with an alias", :dc, :type
      end

      describe "datacite.creator" do
        it_behaves_like "a metadata profile accessor with an alias", :datacite, :creator
      end
      describe "datacite.title" do
        it_behaves_like "a metadata profile accessor with an alias", :datacite, :title
      end
      describe "datacite.publisher" do
        it_behaves_like "a metadata profile accessor with an alias", :datacite, :publisher
      end
      describe "datacite.publicationyear" do
        it_behaves_like "a metadata profile accessor with an alias", :datacite, :publicationyear
      end
      describe "datacite.resourcetype" do
        it_behaves_like "a metadata profile accessor with an alias", :datacite, :resourcetype
      end

      describe "erc.who" do
        it_behaves_like "a metadata profile accessor with an alias", :erc, :who
      end
      describe "erc.what" do
        it_behaves_like "a metadata profile accessor with an alias", :erc, :what
      end
      describe "erc.when" do
        it_behaves_like "a metadata profile accessor with an alias", :erc, :when
      end
    end

    describe "ANVL output" do
      let(:elements) do
        { "_target" => "http://example.com/path%20with%20spaces",
          "_erc" => "who: Proust, Marcel\nwhat: Remembrance of Things Past",
          "_status" => "public" }
      end
      subject { described_class.new(elements) }
      it "should output the proper format and escape" do
        expect(subject.to_anvl).to eq("\
_target: http://example.com/path%2520with%2520spaces
_erc: who: Proust, Marcel%0Awhat: Remembrance of Things Past
_status: public")
      end
      describe "encoding" do
        before do
          subject.each { |k, v| subject[k] = v.force_encoding(Encoding::US_ASCII) }
        end
        it "should be encoded in UTF-8" do
          expect(subject.to_anvl.encoding).to eq(Encoding::UTF_8)
        end
      end
    end

    describe "coercion" do
      subject { described_class.new(data) }
      context "of nil" do
        let(:data) { nil }
        it "should create be empty" do
          expect(subject).to be_empty
        end
      end
      context "of a string" do
        let(:data) do <<-EOS
_updated: 1416507086
_target: http://example.com/path%2520with%2520spaces
_profile: erc
_erc: who: Proust, Marcel%0Awhat: Remembrance of Things Past
_ownergroup: apitest
_owner: apitest
_export: yes
_created: 1416507086
_status: public
EOS
        end
        it "treats the string as an ANVL document, splitting into keys and values and unescaping" do
          expect(subject).to eq({ "_updated" => "1416507086",
                                           "_target" => "http://example.com/path%20with%20spaces",
                                           "_profile" => "erc",
                                           "_erc" => "who: Proust, Marcel\nwhat: Remembrance of Things Past",
                                           "_ownergroup" => "apitest",
                                           "_owner" => "apitest",
                                           "_export" => "yes",
                                           "_created" => "1416507086",
                                           "_status" => "public" })
        end
      end
      context "of a hash-like object" do
        let(:hsh) do
          { "_updated" => "1416507086",
            "_target" => "http://ezid.cdlib.org/id/ark:/99999/fk4fn19h87",
            "_profile" => "erc",
            "_ownergroup" => "apitest",
            "_owner" => "apitest",
            "_export" => "yes",
            "_created" => "1416507086",
            "_status" => "public" }
        end
        context "which is a normal Hash" do
          let(:data) { hsh }
          it "sets the metadata elements to the hash" do
            expect(subject).to eq(hsh)
          end
        end
        context "which is a Metadata instance" do
          let(:data) { Metadata.new(hsh) }
          it "sets the metadata elements to the hash" do
            expect(subject).to eq(hsh)
          end
        end
      end
    end

  end
end
