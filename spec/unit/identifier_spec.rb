module Ezid
  RSpec.describe Identifier do

    describe ".create" do
      let(:attrs) { {shoulder: TEST_ARK_SHOULDER, profile: "dc", target: "http://example.com"} }
      it "instantiates a new Identifier and saves it" do
        expect(described_class).to receive(:new).with(attrs).and_call_original
        expect_any_instance_of(described_class).to receive(:save) { double }
        described_class.create(attrs)
      end
    end

    describe ".find" do
      it "instantiates a new identifier and loads the metadata" do
        expect(described_class).to receive(:new).with(id: "id").and_call_original
        expect_any_instance_of(described_class).to receive(:load_metadata) { double }
        described_class.find("id")
      end
    end

    describe ".defaults" do
      before { @original_defaults = described_class.defaults }
      after { described_class.defaults = @original_defaults }
      it "can be set via client config" do
        Client.config.identifier.defaults = {status: "reserved"}
        expect(described_class.defaults).to eq({status: "reserved"})
      end
    end

    describe "#initialize" do
      describe "with metadata" do
        describe "via the :metadata argument" do
          subject { described_class.new(metadata: "_profile: dc\n_target: http://example.com") }
          it "sets the metadata" do
            expect(subject.profile).to eq("dc")
            expect(subject.target).to eq("http://example.com")
          end
        end
        describe "via keyword arguments" do
          subject { described_class.new(profile: "dc", target: "http://example.com") }
          it "sets the metadata" do
            expect(subject.profile).to eq("dc")
            expect(subject.target).to eq("http://example.com")
          end
        end
      end
      describe "default metadata" do
        before do
          allow(described_class).to receive(:defaults) { {profile: "dc", status: "reserved"} }
        end
        it "sets the default metadata" do
          expect(subject.profile).to eq("dc")
          expect(subject.status).to eq("reserved")
        end
        context "when explicit arguments override the defaults" do
          subject { described_class.new(shoulder: TEST_ARK_SHOULDER, status: "public") }
          it "overrides the defaults" do
            expect(subject.profile).to eq("dc")
            expect(subject.status).to eq("public")
          end
        end
      end
    end

    describe "#update" do
      let(:metadata) { {"status" => "unavailable"} }
      subject { described_class.new(id: "id") }
      it "updates the metadata and saves" do
        expect(subject).to receive(:update_metadata).with(metadata)
        expect(subject).to receive(:save) { double }
        subject.update(metadata)
      end
    end

    describe "#update_metadata" do
      it "updates the metadata" do
        subject.update_metadata(:status => "public", _target: "localhost", "dc.creator" => "Me")
        expect(subject.metadata.to_h).to eq({"_status"=>"public", "_target"=>"localhost", "dc.creator"=>"Me"})
      end
    end

    describe "#load_metadata" do
      let(:metadata) { "_profile: erc" }
      before { allow(subject).to receive(:id) { "id" } }
      it "initializes the metadata from EZID" do
        expect(subject.client).to receive(:get_identifier_metadata).with("id") { double(id: "id", metadata: metadata) }
        expect(Metadata).to receive(:new).with(metadata)
        subject.load_metadata
      end
    end

    describe "#reset" do
      before { subject.metadata = Metadata.new(status: "public") }
      it "clears the local metadata" do
        expect { subject.reset }.to change { subject.metadata.empty? }.from(false).to(true)
      end
    end

    describe "#persisted?" do
      describe "after initialization" do
        it { is_expected.not_to be_persisted }
      end
      describe "when saving an unpersisted object" do
        before { allow(subject).to receive(:create_or_mint) { nil } }
        it "marks it as persisted" do
          expect { subject.save }.to change(subject, :persisted?).from(false).to(true)
        end
      end
      describe "when saving a persisted object" do
        before do
          allow(subject).to receive(:persisted?) { true }
          allow(subject).to receive(:modify) { nil }
        end
        it "does not change the persisted status" do
          expect { subject.save }.not_to change(subject, :persisted?)
        end
      end
    end

    describe "#delete" do
      context "when the identifier is reserved" do
        subject { described_class.new(id: "id", status: Identifier::RESERVED) }
        context "and is persisted" do
          before { allow(subject).to receive(:persisted?) { true } }
          it "deletes the identifier" do
            expect(subject.client).to receive(:delete_identifier).with("id") { double(id: "id") }
            subject.delete
            expect(subject).to be_deleted
          end
        end
        context "and is not persisted" do
          before { allow(subject).to receive(:persisted?) { false } }
          it "raises an exception" do
            expect { subject.delete }.to raise_error(Error)
          end
        end
      end
      context "when identifier is not reserved" do
        subject { described_class.new(id: "id", status: Identifier::PUBLIC) }
        it "raises an exception" do
          expect { subject.delete }.to raise_error(Error)
        end
      end
    end

    describe "#save" do
      context "when the identifier is persisted" do
        let(:metadata) { Metadata.new }
        before do
          allow(subject).to receive(:id) { "id" }
          allow(subject).to receive(:persisted?) { true }
          allow(subject).to receive(:metadata) { metadata }
        end
        it "modifies the identifier" do
          expect(subject.client).to receive(:modify_identifier).with("id", metadata) { double(id: "id") }
          subject.save
        end
      end
      context "when the identifier is not persisted" do
        before do
          allow(subject).to receive(:persisted?) { false }
        end
        context "and `id' is present" do
          before { allow(subject).to receive(:id) { "id" } }
          it "creates the identifier" do
            expect(subject.client).to receive(:create_identifier).with("id", subject.metadata) { double(id: "id") }
            subject.save
          end
        end
        context "and `id' is not present" do
          context "and `shoulder' is present" do
            before { allow(subject).to receive(:shoulder) { TEST_ARK_SHOULDER } }
            it "mints the identifier" do
              expect(subject.client).to receive(:mint_identifier).with(TEST_ARK_SHOULDER, subject.metadata) { double(id: "id") }
              subject.save
            end
          end
          context "and `shoulder' is not present" do
            before { allow(Client.config).to receive(:default_shoulder) { nil } }
            it "raises an exception" do
              expect { subject.save }.to raise_error(Error)
            end
          end
        end
      end
    end

    describe "boolean status methods" do
      context "when the identifier is public" do
        before { subject.public! }
        it { is_expected.to be_public }
        it { is_expected.not_to be_reserved }
        it { is_expected.not_to be_unavailable }
      end
      context "when the identifier is reserved" do
        before { subject.status = Identifier::RESERVED }
        it { is_expected.not_to be_public }
        it { is_expected.to be_reserved }
        it { is_expected.not_to be_unavailable }
      end
      context "when the identifier is unavailable" do
        context "and it has no reason" do
          before { subject.unavailable! }
          it { is_expected.not_to be_public }
          it { is_expected.not_to be_reserved }
          it { is_expected.to be_unavailable }
        end
        context "and it has a reason" do
          before { subject.unavailable!("withdrawn") }
          it { is_expected.not_to be_public }
          it { is_expected.not_to be_reserved }
          it { is_expected.to be_unavailable }
        end
      end
    end

    describe "status-changing methods" do
      subject { described_class.new(id: "id", status: status) }
      describe "#unavailable!" do
        context "when the status is \"unavailable\"" do
          let(:status) { "#{Identifier::UNAVAILABLE} | whatever" }
          context "and no reason is given" do
            it "logs a warning" do
              pending "https://github.com/duke-libraries/ezid-client/issues/46"
              allow_message_expectations_on_nil
              expect(subject.logger).to receive(:warn)
              subject.unavailable!
            end
            it "does not change the status" do
              expect { subject.unavailable! }.not_to change(subject, :status)
            end
          end
          context "and a reason is given" do
            it "logs a warning" do
              pending "https://github.com/duke-libraries/ezid-client/issues/46"
              allow_message_expectations_on_nil
              expect(subject.logger).to receive(:warn)
              subject.unavailable!("because")
            end
            it "should change the status" do
              expect { subject.unavailable!("because") }.to change(subject, :status).from(status).to("#{Identifier::UNAVAILABLE} | because")
            end
          end
        end
        context "when the status is \"reserved\"" do
          let(:status) { Identifier::RESERVED }
          context "and persisted" do
            before { allow(subject).to receive(:persisted?) { true } }
            it "raises an exception" do
              expect { subject.unavailable! }.to raise_error(Error)
            end
          end
          context "and not persisted" do
            before { allow(subject).to receive(:persisted?) { false } }
            it "changes the status" do
              expect { subject.unavailable! }.to change(subject, :status).from(Identifier::RESERVED).to(Identifier::UNAVAILABLE)
            end
          end
        end
        context "when the status is \"public\"" do
          let(:status) { Identifier::PUBLIC }
          context "and no reason is given" do
            it "changes the status" do
              expect { subject.unavailable! }.to change(subject, :status).from(Identifier::PUBLIC).to(Identifier::UNAVAILABLE)
            end
          end
          context "and a reason is given" do
            it "changes the status and appends the reason" do
              expect { subject.unavailable!("withdrawn") }.to change(subject, :status).from(Identifier::PUBLIC).to("#{Identifier::UNAVAILABLE} | withdrawn")
            end
          end
        end
      end
      describe "#public!" do
        subject { described_class.new(id: "id", status: Identifier::UNAVAILABLE) }
        it "changes the status" do
          expect { subject.public! }.to change(subject, :status).from(Identifier::UNAVAILABLE).to(Identifier::PUBLIC)
        end
      end
    end

  end
end
