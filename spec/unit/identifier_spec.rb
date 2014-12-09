module Ezid
  RSpec.describe Identifier do

    describe ".create" do
      let(:attrs) { {shoulder: TEST_ARK_SHOULDER, profile: "dc", target: "http://example.com"} }
      it "should instantiate a new Identifier and save it" do        
        expect(described_class).to receive(:new).with(attrs).and_call_original
        expect_any_instance_of(described_class).to receive(:save) { double }
        described_class.create(attrs)
      end
      describe "when given neither an id nor a shoulder" do
        before { allow(described_class).to receive(:defaults) {} }
        it "should raise an exception" do
          expect { described_class.create }.to raise_error
        end
      end
    end

    describe ".find" do
      it "should instantiate a new identifier and reload" do
        expect(described_class).to receive(:new).with(id: "id").and_call_original
        expect_any_instance_of(described_class).to receive(:reload) { double }
        described_class.find("id")
      end
    end

    describe ".defaults" do
      before { @original_defaults = described_class.defaults }
      after { described_class.defaults = @original_defaults }
      it "should be settable via client config" do
        Client.config.identifier.defaults = {status: "reserved"}
        expect(described_class.defaults).to eq({status: "reserved"})
      end
    end

    describe "#initialize" do
      describe "with metadata" do
        describe "via the :metadata argument" do
          subject { described_class.new(metadata: "_profile: dc\n_target: http://example.com") }
          it "should set the metadata" do
            expect(subject.profile).to eq("dc")
            expect(subject.target).to eq("http://example.com")
          end
        end
        describe "via keyword arguments" do
          subject { described_class.new(profile: "dc", target: "http://example.com") }
          it "should set the metadata" do
            expect(subject.profile).to eq("dc")
            expect(subject.target).to eq("http://example.com")
          end
        end
      end
      describe "default metadata" do
        before do
          allow(described_class).to receive(:defaults) { {profile: "dc", status: "reserved"} }
        end
        it "should set the default metadata" do
          expect(subject.profile).to eq("dc")
          expect(subject.status).to eq("reserved")
        end
        context "when explicit arguments override the defaults" do
          subject { described_class.new(shoulder: TEST_ARK_SHOULDER, status: "public") }
          it "should override the defaults" do
            expect(subject.profile).to eq("dc")
            expect(subject.status).to eq("public")
          end
        end
      end
    end
    
    describe "#update" do
      let(:metadata) { {"status" => "unavailable"} }
      subject { described_class.new(id: "id") }
      it "should update the metadata and save" do
        expect(subject).to receive(:update_metadata).with(metadata)
        expect(subject).to receive(:save) { double }
        subject.update(metadata)
      end
    end

    describe "#reload" do
      let(:metadata) { "_profile: erc" }
      before { allow(subject).to receive(:id) { "id" } }
      it "should reinitialize the metadata from EZID" do
        expect(subject.client).to receive(:get_identifier_metadata).with("id") { double(id: "id", metadata: metadata) }
        expect(Metadata).to receive(:new).with(metadata)
        subject.reload
      end
    end

    describe "#reset" do
      it "should clear the local metadata" do
        expect(subject.metadata).to receive(:clear)
        subject.reset
      end
    end

    describe "#persisted?" do
      it "should be false if id is nil" do
        expect(subject).not_to be_persisted
      end
      context "when `created' is nil" do
        before { allow(subject).to receive(:id) { "ark:/99999/fk4fn19h88" } }
        it "should be false" do
          expect(subject).not_to be_persisted
        end
      end
      context "when id and `created' are present" do
        before do
          allow(subject).to receive(:id) { "ark:/99999/fk4fn19h88" }
          allow(subject.metadata).to receive(:created) { Time.at(1416507086) }
        end
        it "should be true" do
          expect(subject).to be_persisted
        end
      end
    end

    describe "#delete" do
      subject { described_class.new(id: "id", status: "reserved") }
      it "should delete the identifier" do
        expect(subject.client).to receive(:delete_identifier).with("id") { double(id: "id") }
        subject.delete
        expect(subject).to be_deleted
      end
    end

    describe "#save" do
      before { allow(subject).to receive(:reload) { double } }
      context "when the identifier is persisted" do
        before do
          allow(subject).to receive(:id) { "id" }
          allow(subject).to receive(:persisted?) { true }
        end
        it "should modify the identifier" do
          expect(subject.client).to receive(:modify_identifier).with("id", {}) { double(id: "id") }
          subject.save
        end
      end
      context "when the identifier is not persisted" do
        before do
          allow(subject).to receive(:persisted?) { false }
        end
        context "and `id' is present" do
          before { allow(subject).to receive(:id) { "id" } }
          it "should create the identifier" do
            expect(subject.client).to receive(:create_identifier).with("id", {}) { double(id: "id") }
            subject.save
          end
        end
        context "and `id' is not present" do
          context "and `shoulder' is present" do
            before { allow(subject).to receive(:shoulder) { TEST_ARK_SHOULDER } }
            it "should mint the identifier" do
              expect(subject.client).to receive(:mint_identifier).with(TEST_ARK_SHOULDER, {}) { double(id: "id") }
              subject.save
            end
          end
          context "and `shoulder' is not present" do
            before { allow(Client.config).to receive(:default_shoulder) { nil } }
            it "should raise an exception" do
              expect { subject.save }.to raise_error
            end
          end
        end
      end
    end

    describe "boolean status methods" do
      context "when the status is 'public'" do
        before { allow(subject.metadata).to receive(:status) { Identifier::PUBLIC } }
        it { is_expected.to be_public } 
        it { is_expected.not_to be_reserved }
        it { is_expected.not_to be_unavailable }
      end
      context "when the status is 'reserved'" do
        before { allow(subject.metadata).to receive(:status) { Identifier::RESERVED } }
        it { is_expected.not_to be_public } 
        it { is_expected.to be_reserved }
        it { is_expected.not_to be_unavailable }
      end
      context "when the status is 'unavailable'" do
        before { allow(subject.metadata).to receive(:status) { Identifier::UNAVAILABLE } }
        it { is_expected.not_to be_public } 
        it { is_expected.not_to be_reserved }
        it { is_expected.to be_unavailable }
      end
    end

  end
end
