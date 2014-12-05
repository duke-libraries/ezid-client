module Ezid
  RSpec.describe Identifier do

    describe ".create" do
      describe "when given an id" do
        let(:id) { "ark:/99999/fk4zzzzzzz" }
        subject { described_class.create(id: id) }
        before do
          allow_any_instance_of(Client).to receive(:create_identifier).with(id, {}) { double(id: id) }
          allow_any_instance_of(Client).to receive(:get_identifier_metadata).with(id) { double(metadata: {}) }
        end
        it "should create an identifier" do
          expect(subject).to be_a(described_class)
          expect(subject.id).to eq(id)
        end
      end
      describe "when given a shoulder (and no id)" do
        let(:id) { "ark:/99999/fk4fn19h88" }
        subject { described_class.create(shoulder: ARK_SHOULDER) }
        before do
          allow_any_instance_of(Client).to receive(:mint_identifier).with(ARK_SHOULDER, {}) { double(id: id) }
          allow_any_instance_of(Client).to receive(:get_identifier_metadata).with(id) { double(metadata: {}) }
        end
        it "should mint an identifier" do
          expect(subject).to be_a(described_class)
          expect(subject.id).to eq(id)
        end
      end
      describe "when given neither an id nor a shoulder" do
        it "should raise an exception" do
          expect { described_class.create }.to raise_error
        end
      end
      describe "with metadata" do
        it "should send the metadata"
      end
    end

    describe ".find" do
      describe "when the id exists" do
        let(:id) { "ark:/99999/fk4fn19h88" }
        subject { described_class.find(id) }
        before do
          allow_any_instance_of(Client).to receive(:get_identifier_metadata).with(id) { double(id: id, metadata: {}) }
        end
        it "should get the identifier" do
          expect(subject).to be_a(Identifier)
          expect(subject.id).to eq(id)
        end
      end
      describe "when the id does not exist" do
        let(:id) { "ark:/99999/fk4zzzzzzz" }
        before do
          allow_any_instance_of(Client).to receive(:get_identifier_metadata).with(id).and_raise(Error)
        end
        it "should raise an exception" do
          expect { described_class.find(id) }.to raise_error
        end
      end
    end
    
    describe "#update" do
      let(:id) { "ark:/99999/fk4fn19h88" }
      let(:metadata) { {"status" => "unavailable"} }
      subject { described_class.new(id: id) }
      before do
        allow(subject).to receive(:persisted?) { true }
        allow(subject.client).to receive(:modify_identifier).with(id, subject.metadata) do
          double(id: id, metadata: {})
        end
      end
      it "should update the metadata" do
        expect(subject).to receive(:update_metadata).with(metadata)
        subject.update(metadata)
      end
      it "should save the identifier" do
        expect(subject).to receive(:save)
        subject.update(metadata)
      end
    end

    describe "#reload" do
      let(:id) { "ark:/99999/fk4fn19h88" }
      let(:metadata) { "_created: 1416507086" }
      subject { described_class.new(id: id) }
      before do
        allow(subject.client).to receive(:get_identifier_metadata).with(id) { double(metadata: metadata) }
      end
      it "should reinitialize the metadata from EZID" do
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
      let(:id) { "ark:/99999/fk4zzzzzzz" }
      subject { described_class.new(id: id, status: "reserved") }
      before do
        allow_any_instance_of(Client).to receive(:delete_identifier).with(id) { double(id: id) }
      end
      it "should delete the identifier" do
        expect(subject.client).to receive(:delete_identifier).with(id)
        subject.delete
        expect(subject).to be_deleted
      end
    end

    describe "#save" do
      let(:id) { "ark:/99999/fk4zzzzzzz" }
      before do
        allow(subject.client).to receive(:get_identifier_metadata).with(id) { double(metadata: {}) }
      end
      context "when the identifier is persisted" do
        before do
          allow_any_instance_of(Client).to receive(:modify_identifier).with(id, {}) { double(id: id) }
          allow(subject).to receive(:id) { id }
          allow(subject).to receive(:persisted?) { true }
        end
        it "should modify the identifier" do
          expect(subject.client).to receive(:modify_identifier).with(id, {})
          subject.save
        end
      end
      context "when the identifier is not persisted" do
        before do
          allow(subject).to receive(:persisted?) { false }
        end
        context "and `id' is present" do
          before do
            allow(subject).to receive(:id) { id }
            allow_any_instance_of(Client).to receive(:create_identifier).with(id, {}) { double(id: id) }
          end
          it "should create the identifier" do
            expect(subject.client).to receive(:create_identifier).with(id, {})
            subject.save
          end
        end
        context "and `id' is not present" do
          context "and `shoulder' is present" do
            before do
              allow(subject).to receive(:shoulder) { ARK_SHOULDER }
              allow_any_instance_of(Client).to receive(:mint_identifier).with(ARK_SHOULDER, {}) { double(id: id) }
            end
            it "should mint the identifier" do
              expect(subject.client).to receive(:mint_identifier).with(ARK_SHOULDER, {})
              subject.save
            end
          end
          context "and `shoulder' is not present" do
            it "should raise an exception" do
              expect { subject.save }.to raise_error
            end
          end
        end
      end
    end

  end
end
