module Ezid
  RSpec.describe Metadata do

    describe "reserved elements" do
      describe "readers" do
        Metadata::RESERVED_ELEMENTS.each do |element|
          it "should have a reader for '#{element}'" do
            expect(subject).to receive(:reader).with(element)
            reader = (element == "_crossref") ? element : element.sub("_", "")
            subject.send(reader)
          end
        end
        describe "for time-based elements" do
          Metadata::RESERVED_TIME_ELEMENTS.each do |element|
            context "\"#{element}\"" do
              before { subject[element] = "1416507086" }
              it "should have a reader than returns a Time instance" do
                expect(subject).to receive(:reader).with(element).and_call_original
                expect(subject.send(element.sub("_", ""))).to eq(Time.parse("2014-11-20 13:11:26 -0500"))
              end
            end
          end
        end
      end
      describe "writers" do
        Metadata::RESERVED_READWRITE_ELEMENTS.each do |element|
          next if element == "_crossref"
          it "should have a writer for '#{element}'" do
            expect(subject).to receive(:writer).with(element, "value")
            writer = ((element == "_crossref") ? element : element.sub("_", "")).concat("=")
            subject.send(writer, "value")
          end
        end
      end
    end

    describe "metadata profiles" do
      Metadata::PROFILES.each do |profile, elements|
        describe "the '#{profile}' metadata profile" do
          describe "readers" do
            elements.each do |element|
              it "should have a reader for '#{profile}.#{element}'" do
                expect(subject).to receive(:reader).with("#{profile}.#{element}")
                subject.send("#{profile}_#{element}")
              end
            end
          end
          describe "writers" do
            elements.each do |element|
              it "should have a writer for '#{profile}.#{element}'" do
                expect(subject).to receive(:writer).with("#{profile}.#{element}", "value")
                subject.send("#{profile}_#{element}=", "value")
              end
            end
          end
          next if profile == "dc"
          it "should have a reader for '#{profile}'" do
            expect(subject).to receive(:reader).with(profile)
            subject.send(profile)
          end
          it "should have a writer for '#{profile}'" do
            expect(subject).to receive(:writer).with(profile, "value")
            subject.send("#{profile}=", "value")
          end
        end
      end
    end

    describe "custom element" do
      let(:element) { Metadata::Element.new("custom", true) }
      before { described_class.register_element :custom }
      after { described_class.send(:unregister_element, :custom) }
      it "should have a reader" do
        expect(subject).to receive(:reader).with("custom")
        subject.custom
      end
      it "should have a writer" do
        expect(subject).to receive(:writer).with("custom", "value")
        subject.custom = "value"
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
          subject.each_key { |k| subject[k] = subject[k].force_encoding(Encoding::US_ASCII) }
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
        it "should create an empty hash" do
          expect(subject).to eq({})
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
        it "should treat the string as an ANVL document, splitting into keys and values and unescaping" do
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
          it "should set the metadata to the hash" do
            expect(subject).to eq(hsh)
          end
        end
        context "which is a Metadata instance" do
          let(:data) { Metadata.new(hsh) }
          it "should set the metadata to the hash" do
            expect(subject).to eq(hsh)
          end
        end
      end
    end

  end
end
