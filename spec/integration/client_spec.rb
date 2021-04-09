require "time"

module Ezid
  RSpec.describe Client, ezid: true do

    shared_examples "an EZID client" do |client|
      it "should mint and modify" do
        minted = client.mint_identifier(TEST_ARK_SHOULDER, "_status: reserved")
        expect(minted).to be_success
        @id = minted.id
        modified = client.modify_identifier(@id, "dc.title" => "Test")
        expect(modified).to be_success
        retrieved = client.get_identifier_metadata(@id)
        expect(retrieved).to be_success
        expect(retrieved.metadata).to match(/dc.title: Test/)
        deleted = client.delete_identifier(@id)
        expect(deleted).to be_success
        expect { client.get_identifier_metadata(@id) }.to raise_error(Error)
      end
    end

    describe "initialization with a block" do
      it "should wrap the block in a session" do
        expect_any_instance_of(described_class).to receive(:login).and_call_original
        expect_any_instance_of(described_class).to receive(:logout).and_call_original
        described_class.new do |client|
          expect(client.session).to be_open
        end
      end
    end

    describe "authentication" do
      describe "#login" do
        it "should open a session" do
          expect(subject.session).to be_closed
          subject.login
          expect(subject.session).to be_open
        end
      end
      describe "#logout" do
        before { subject.login }
        it "should close the session" do
          expect(subject.session).to be_open
          subject.logout
          expect(subject.session).to be_closed
        end
      end
      describe "without a session" do
        it "should send the user name and password" do
          expect_any_instance_of(Net::HTTP::Post).to receive(:basic_auth).with(subject.user, subject.password).and_call_original
          subject.mint_identifier(TEST_ARK_SHOULDER)
        end
      end
    end

    describe "identifier lifecycle management" do
      describe "with a session" do
        Client.new do |client|
          it_behaves_like "an EZID client", client
        end
      end
      describe "without a session" do
        it_behaves_like "an EZID client", Client.new
      end
    end

    describe "batch download" do
      before do
        r = subject.mint_identifier
        r = subject.get_identifier_metadata(r.id)
        metadata = Metadata.new(r.metadata)
        @created = metadata.created.iso8601
      end
      it "should return a valid URL" do
        response = subject.batch_download(format: "anvl", createdAfter: @created, permanence: "test")
        expect(response).to be_success
        expect(response.download_url).to match(/^http:\/\/ezid.cdlib.org\/download\/[^\/]+.gz$/)
      end
    end

  end
end
