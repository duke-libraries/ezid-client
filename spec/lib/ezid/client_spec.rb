module Ezid
  RSpec.describe Client do
    describe "initialization" do
      describe "without a block" do
        it "should not be logged in" do
          expect(subject).not_to be_logged_in
        end
      end
      describe "with a block", :vcr do
        it "should be logged in" do
          described_class.new do |client|
            expect(client).to be_logged_in
          end
        end
      end
    end    
    describe "authentication", :vcr do
      describe "logging in" do
        before { subject.login }
        it "should be logged in" do
          expect(subject).to be_logged_in
        end
      end
      describe "logging out" do
        before { subject.login }
        it "should not be logged in" do
          subject.logout
          expect(subject).not_to be_logged_in
        end
      end
    end
    describe "creating an identifier", :vcr do
      # TODO
    end
    describe "minting an identifier", :vcr do
      describe "which is an ARK" do
        it "should be a success" do
          response = subject.mint_identifier(ARK_SHOULDER)
          expect(response).to be_success
          expect(response.message).to match(/#{ARK_SHOULDER}/)
        end
      end
      describe "which is a DOI" do
        it "should be a sucess" do
          response = subject.mint_identifier(DOI_SHOULDER, doi_metadata)
          expect(response).to be_success
          expect(response.message).to match(/#{DOI_SHOULDER}/)
          expect(response.message).to match(/\| ark:/)
        end
      end
    end
    describe "getting identifier metadata", :vcr do
      let(:identifier) { subject.mint_identifier(ARK_SHOULDER).identifier }
      it "should return the metadata" do
        response = subject.get_identifier_metadata(identifier)
        expect(response.body).to match(/_status: public/)
      end
    end
    describe "modifying an identifier", :vcr do
      let(:identifier) { subject.mint_identifier(ARK_SHOULDER).identifier }
      before { subject.modify_identifier(identifier, "dc.title" => "Test") }
      it "should update the metadata" do
        response = subject.get_identifier_metadata(identifier)
        expect(response.body).to match(/dc.title: Test/)
      end
    end
    describe "deleting an identifier", :vcr do
      let(:identifier) { subject.mint_identifier(ARK_SHOULDER, "_status" => "reserved").identifier }
      before { subject.delete_identifier(identifier) }
      it "should delete the identifier" do
        expect { subject.get_identifier_metadata(identifier) }.to raise_error
      end
    end
    describe "server status", :vcr do
      let(:response) { subject.server_status("*") }
      it "should report the status of EZID and subsystems" do
        expect(response).to be_success
        expect(response.message).to eq("EZID is up")
      end
    end
  end
end

