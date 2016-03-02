module Ezid
  RSpec.describe Identifier do

    before {
      @identifier = described_class.mint(TEST_ARK_SHOULDER, target: "http://example.com")
    }

    describe "CRUD operations" do
      describe "mint" do
        subject { @identifier }
        it { is_expected.to be_a(described_class) }
      end
      describe "create" do
        subject { described_class.create("#{@identifier}/123") }
        it "should create the identifier" do
          expect(subject).to be_a(described_class)
          expect(subject.id).to eq("#{@identifier}/123")
        end
      end
      describe "retrieve" do
        subject { described_class.find(@identifier.id) }
        it "instantiates the identifier" do
          expect(subject).to be_a(described_class)
          expect(subject.id).to eq(@identifier.id)
          expect(subject.target).to eq("http://example.com")
        end
      end
      describe "update" do
        specify {
          subject.target = "http://google.com"
          subject.save
          expect(subject.target).to eq("http://google.com")
        }
        specify {
          subject.update(target: "http://www.microsoft.com")
          expect(subject.target).to eq("http://www.microsoft.com")
        }
      end
      describe "delete" do
        subject { described_class.mint(TEST_ARK_SHOULDER, status: "reserved") }
        it "deletes the identifier" do
          subject.delete
          expect(subject).to be_deleted
          expect { described_class.find(subject.id) }.to raise_error(IdentifierNotFoundError)
        end
      end
    end
  end
end
