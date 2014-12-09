

module Ezid
  RSpec.describe Identifier do

    describe "CRUD operations" do
      describe "create" do
        describe "with a shoulder" do
          subject { described_class.create(shoulder: TEST_ARK_SHOULDER) }
          it "should mint an identifier" do
            expect(subject).to be_a(described_class)
            expect(subject.id).to match(/#{TEST_ARK_SHOULDER}/)
          end
        end
        describe "with an id" do
          let(:minted) { described_class.create(shoulder: TEST_ARK_SHOULDER) }
          subject { described_class.create(id: "#{minted}/123") }
          it "should create the identifier" do
            expect(subject).to be_a(described_class)
            expect(subject.id).to eq("#{minted}/123")
          end
        end
      end

      describe "retrieve" do
        let(:minted) { described_class.create(shoulder: TEST_ARK_SHOULDER, target: "http://example.com") }
        subject { described_class.find(minted.id) }
        it "should instantiate the identifier" do
          expect(subject).to be_a(described_class)
          expect(subject.id).to eq(minted.id)
          expect(subject.target).to eq("http://example.com")
        end
      end

      describe "update" do
        subject { described_class.create(shoulder: TEST_ARK_SHOULDER, target: "http://google.com") }
        before do
          subject.target = "http://example.com"
          subject.save
        end
        it "should update the metadata" do
          expect(subject.target).to eq("http://example.com")
        end
      end

      describe "delete" do
        subject { described_class.create(shoulder: TEST_ARK_SHOULDER, status: "reserved") }
        before { subject.delete }
        it "should delete the identifier" do
          expect { described_class.find(subject.id) }.to raise_error
        end
      end
    end
  end
end
