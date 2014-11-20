module Ezid
  RSpec.describe Client do
    describe "initialization" do
      describe "without a block" do
        subject { described_class.new(user: TEST_USER) }
        it "should not be logged in" do
          expect(subject).not_to be_logged_in
        end
      end
      describe "with a block", :vcr do
        it "should be logged in" do
          described_class.new(user: TEST_USER) do |client|
            expect(client).to be_logged_in
          end
        end
      end
    end
    
    describe "authentication", :vcr do
      subject { described_class.new(user: TEST_USER) }
      describe "logging in" do
        before { subject.login }
        it "should be logged in" do
          expect(subject).to be_logged_in
        end
      end
      describe "logging out" do
        before { subject.login; subject.logout }
        it "should not be logged in" do
          expect(subject).not_to be_logged_in
        end
      end
    end
    describe "creating an identifier" do
      # TODO
    end
    describe "minting an identifier", :vcr do
      let(:client) { described_class.new(user: TEST_USER) }
      describe "which is an ARK" do
        subject { client.mint_identifier(ARK_SHOULDER) }
        it "should be a success" do
          expect(subject).to be_success
          expect(subject.message).to match(/#{ARK_SHOULDER}/)
        end
      end
      describe "which is a DOI" do
        subject { client.mint_identifier(DOI_SHOULDER, doi_metadata) }
        it "should be a sucess" do
          expect(subject).to be_success
          expect(subject.message).to match(/#{DOI_SHOULDER}/)
          expect(subject.message).to match(/\| ark:/)
        end
      end
    end
    describe "getting identifier metadata", :vcr do
      let(:client) { described_class.new(user: TEST_USER) }
      let(:metadata) { Metadata.new("dc.title" => "Test") }
      let(:identifier) { client.mint_identifier(ARK_SHOULDER, metadata).message }
      subject { Metadata.new(client.get_identifier_metadata(identifier).content.last) }
      it "should return the metadata" do
        expect(subject["dc.title"]).to eq("Test")
      end
    end
    describe "modifying an identifier" do
      # TODO
    end
    describe "deleting an identifier" do
      # TODO
    end
    describe "server status", :vcr do
      let(:client) { described_class.new(user: TEST_USER) }
      subject { client.server_status("*") }
      it "should report the status of EZID and subsystems" do
        expect(subject).to be_success
        expect(subject.message).to eq "EZID is up"        
      end
    end
  end
end

