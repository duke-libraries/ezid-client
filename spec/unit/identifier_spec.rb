module Ezid
  RSpec.describe Identifier do

    describe "class methods" do

      describe ".load" do
        subject { described_class.load("ark:/99999/fk4086hs23", metadata) }
        describe "with ANVL metadata" do
          let(:metadata) do
            <<-EOS
_updated: 1488227717
_target: http://example.com
_profile: erc
_ownergroup: apitest
_owner: apitest
_export: yes
_created: 1488227717
_status: public
            EOS
          end
          its(:remote_metadata) {
            is_expected.to eq({"_updated"=>"1488227717",
                               "_target"=>"http://example.com",
                               "_profile"=>"erc",
                               "_ownergroup"=>"apitest",
                               "_owner"=>"apitest",
                               "_export"=>"yes",
                               "_created"=>"1488227717",
                               "_status"=>"public"})
          }
        end
        describe "with nil" do
          let(:metadata) { nil }
          its(:remote_metadata) { is_expected.to be_empty }
        end
      end
      describe ".create" do
        describe "with id and metadata args" do
          it "instantiates a new Identifier and saves it" do
            expect_any_instance_of(described_class).to receive(:save) { double(id: "id") }
            described_class.create("id", profile: "dc", target: "http://example.com")
          end
        end
        describe "with an id arg" do
          it "instantiates a new Identifier and saves it" do
            expect_any_instance_of(described_class).to receive(:save) { double(id: "id") }
            described_class.create("id")
          end
        end
        describe "with a hash metadata arg", deprecated: true do
          it "mints a new Identifier" do
            expect(described_class).to receive(:mint).with(nil, profile: "dc", target: "http://example.com")
            described_class.create(profile: "dc", target: "http://example.com")
          end
        end
        describe "with no args", deprecated: true do
          it "mints a new Identifier" do
            expect(described_class).to receive(:mint).with(nil, nil)
            described_class.create
          end
        end
      end
      describe ".mint" do
        let(:attrs) { {profile: "dc", target: "http://example.com"} }
        let(:args) { [TEST_ARK_SHOULDER, attrs] }
        it "instantiates a new Identifier and saves it" do
          expect_any_instance_of(described_class).to receive(:save) { double(id: "id") }
          described_class.mint(*args)
        end
      end
      describe ".modify" do
        let(:args) { ["id", {profile: "dc", target: "http://example.com"}] }
        it "instantiates a new Indentifier and modifies it" do
          expect_any_instance_of(described_class).not_to receive(:save)
          expect_any_instance_of(described_class).to receive(:modify!)
          described_class.modify(*args)
        end
      end
      describe ".find" do
        it "instantiates a new identifier and loads the metadata" do
          expect_any_instance_of(described_class).to receive(:id=).with("id").and_call_original
          expect_any_instance_of(described_class).to receive(:load_metadata) {
            double(id: "id", metadata: nil)
          }
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
    end

    describe "instance methods" do

      describe "#initialize" do
        before {
          allow(described_class).to receive(:defaults) { defaults }
        }
        let(:defaults) { {} }
        describe "with no arguments" do
          its(:id) { is_expected.to be_nil }
          describe "and no default metadata" do
            its(:metadata) { is_expected.to be_empty }
          end
          describe "and with default metadata" do
            let(:defaults) { {export: "no"} }
            its(:metadata) { is_expected.to eq({"_export"=>"no"}) }
          end
        end
        describe "with an id and no metadata" do
          subject { described_class.new("id") }
          its(:id) { is_expected.to eq("id") }
          describe "and no default metadata" do
            its(:metadata) { is_expected.to be_empty }
          end
          describe "and with default metadata" do
            let(:defaults) { {export: "no"} }
            its(:metadata) { is_expected.to eq({"_export"=>"no"}) }
          end
        end
        describe "with an id and metadata" do
          subject { described_class.new("id", metadata: "_profile: dc\n_target: http://example.com", status: "reserved") }
          its(:id) { is_expected.to eq("id") }
          describe "and no default metadata" do
            its(:metadata) { is_expected.to eq("_profile"=>"dc", "_target"=>"http://example.com", "_status"=>"reserved") }
          end
          describe "and with default metadata" do
            let(:defaults) { {export: "no", status: "public"} }
            its(:metadata) { is_expected.to eq("_profile"=>"dc", "_target"=>"http://example.com", "_status"=>"reserved", "_export"=>"no") }
          end
        end
        describe "with only metadata" do
          subject { described_class.new(metadata: "_profile: dc\n_target: http://example.com", status: "reserved") }
          its(:id) { is_expected.to be_nil }
          describe "and no default metadata" do
            its(:metadata) { is_expected.to eq("_profile"=>"dc", "_target"=>"http://example.com", "_status"=>"reserved") }
          end
          describe "and with default metadata" do
            let(:defaults) { {export: "no", status: "public"} }
            its(:metadata) { is_expected.to eq("_profile"=>"dc", "_target"=>"http://example.com", "_status"=>"reserved", "_export"=>"no") }
          end
        end
        describe "deprecated hash options", deprecated: true do
          describe "id" do
            subject { described_class.new(id: "id") }
            its(:id) { is_expected.to eq("id") }
            specify {
              expect { described_class.new("id", id: "id") }.to raise_error(ArgumentError)
            }
          end
          describe "shoulder" do
            subject { described_class.new(shoulder: "shoulder") }
            its(:shoulder) { is_expected.to eq("shoulder") }
          end
          describe "client" do
            let(:client) { double }
            subject { described_class.new(client: client) }
            its(:client) { is_expected.to_not eq(client) }
          end
        end
      end # initialize

      describe "#update" do
        let(:metadata) { {"status" => "unavailable"} }
        subject { described_class.new("id") }
        it "updates the metadata and saves" do
          expect(subject).to receive(:update_metadata).with(metadata)
          expect(subject).to receive(:save) { double }
          subject.update(metadata)
        end
      end

      describe "#modify!" do
        describe "when the Identifier has no id" do
          specify {
            expect { subject.modify! }.to raise_error(Error)
          }
        end
        describe "when the Identifier has an id" do
          specify {
            subject.id = "id"
            expect(subject).not_to receive(:save)
            expect(subject).to receive(:modify)
            subject.modify!
          }
          describe "when the identifier does not exist" do
            specify {
              subject.id = "id"
              allow(subject.client).to receive(:modify_identifier).and_raise(IdentifierNotFoundError)
              expect { subject.modify! }.to raise_error(IdentifierNotFoundError)
            }
          end
        end
      end

      describe "#update_metadata" do
        it "updates the metadata" do
          subject.update_metadata(:status => "public", _target: "localhost", "dc.creator" => "Me")
          expect(subject.metadata.to_h).to eq({"_status"=>"public", "_target"=>"localhost", "dc.creator"=>"Me"})
        end
      end

      describe "#load_metadata" do
        subject { described_class.new("id") }
        let(:metadata) { "_profile: erc" }
        it "replaces the remote metadata with metadata from EZID" do
          expect(subject.client).to receive(:get_identifier_metadata).with("id") { double(id: "id", metadata: metadata) }
          subject.load_metadata
          expect(subject.remote_metadata).to eq({"_profile"=>"erc"})
          expect(subject).to be_persisted
        end
      end

      describe "#load_metadata!" do
        subject { described_class.new("id") }
        let(:metadata) { "_profile: erc" }
        it "replaces the remote metadata with the provided metadata" do
          subject.load_metadata!(metadata)
          expect(subject.remote_metadata).to eq({"_profile"=>"erc"})
          expect(subject).to be_persisted
        end
      end

      describe "#reset_metadata" do
        before {
          subject.status = "public"
          subject.remote_metadata.profile = "dc"
        }
        it "clears the local metadata" do
          expect { subject.reset_metadata }
            .to change { subject.metadata.empty? }
                 .from(false).to(true)
        end
        it "clears the remote metadata" do
          expect { subject.reset_metadata }
            .to change { subject.remote_metadata.empty? }
                 .from(false).to(true)
        end
      end

      describe "#persisted?" do
        describe "after initialization" do
          it { is_expected.not_to be_persisted }
        end
        describe "when saving an unpersisted object" do
          before {
            allow(subject.client).to receive(:mint_identifier) { double(id: "id") }
            subject.save
          }
          it { is_expected.to be_persisted }
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
          subject { described_class.new("id", status: Status::RESERVED) }
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
          subject { described_class.new("id", status: Status::PUBLIC) }
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
          before { subject.status = Status::RESERVED }
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
        subject { described_class.new("id", status: status) }
        describe "#unavailable!" do
          context "when the status is \"unavailable\"" do
            let(:status) { "#{Status::UNAVAILABLE} | whatever" }
            context "and no reason is given" do
              it "does not change the status" do
                expect { subject.unavailable! }.not_to change(subject, :status)
              end
            end
            context "and a reason is given" do
              it "should change the status" do
                expect { subject.unavailable!("because") }.to change(subject, :status).from(status).to("#{Status::UNAVAILABLE} | because")
              end
            end
          end
          context "when the status is \"reserved\"" do
            let(:status) { Status::RESERVED }
            context "and persisted" do
              before { allow(subject).to receive(:persisted?) { true } }
              it "raises an exception" do
                expect { subject.unavailable! }.to raise_error(Error)
              end
            end
            context "and not persisted" do
              before { allow(subject).to receive(:persisted?) { false } }
              it "changes the status" do
                expect { subject.unavailable! }.to change(subject, :status).from(Status::RESERVED).to(Status::UNAVAILABLE)
              end
            end
          end
          context "when the status is \"public\"" do
            let(:status) { Status::PUBLIC }
            context "and no reason is given" do
              it "changes the status" do
                expect { subject.unavailable! }.to change(subject, :status).from(Status::PUBLIC).to(Status::UNAVAILABLE)
              end
            end
            context "and a reason is given" do
              it "changes the status and appends the reason" do
                expect { subject.unavailable!("withdrawn") }.to change(subject, :status).from(Status::PUBLIC).to("#{Status::UNAVAILABLE} | withdrawn")
              end
            end
          end
        end
        describe "#public!" do
          subject { described_class.new("id", status: Status::UNAVAILABLE) }
          it "changes the status" do
            expect { subject.public! }.to change(subject, :status).from(Status::UNAVAILABLE).to(Status::PUBLIC)
          end
        end
      end
    end

    describe "#metadata" do
      it "is frozen" do
        expect { subject.metadata["foo"] = "bar" }.to raise_error(RuntimeError)
      end
    end
  end
end
