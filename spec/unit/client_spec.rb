module Ezid
  RSpec.describe Client do

    let(:http_response) { double(value: value, body: body) }
    let(:value)   { nil }
    let(:body)    { '' }

    describe "initialization without a block" do
      it "should not login" do
        expect_any_instance_of(described_class).not_to receive(:login)
        described_class.new
      end
    end

    describe "#create_identifier" do
      let(:id) { "ark:/99999/fk4fn19h88" }
      let(:body) { "success: ark:/99999/fk4fn19h88" }
      let(:stub_response) { CreateIdentifierResponse.new(http_response) }

      before do
        allow(CreateIdentifierRequest).to receive(:execute).with(subject, id, nil) { stub_response }
      end

      it "is a success" do
        response = subject.create_identifier(id)
        expect(response).to be_success
        expect(response.id).to eq(id)
      end
    end

    describe "#mint_identifier" do
      let(:stub_response) { MintIdentifierResponse.new(http_response) }

      before do
        allow(MintIdentifierRequest).to receive(:execute).with(subject, TEST_ARK_SHOULDER, nil) { stub_response }
      end

      describe "which is an ARK" do
        let(:body) { "success: ark:/99999/fk4fn19h88" }
        it "should be a success" do
          response = subject.mint_identifier(TEST_ARK_SHOULDER)
          expect(response).to be_success
          expect(response.id).to eq("ark:/99999/fk4fn19h88")
        end
      end

      describe "which is a DOI" do
        let(:body) { "success: doi:10.5072/FK2TEST | ark:/99999/fk4fn19h88" }
        let(:metadata) do
          <<-EOS
datacite.title: Test
datacite.creator: Duke
datacite.publisher: Duke
datacite.publicationyear: 2014
datacite.resourcetype: Other
EOS
        end

        before do
          allow(MintIdentifierRequest).to receive(:execute).with(subject, TEST_DOI_SHOULDER, metadata) { stub_response }
        end

        it "is a success" do
          response = subject.mint_identifier(TEST_DOI_SHOULDER, metadata)
          expect(response).to be_success
          expect(response.id).to eq("doi:10.5072/FK2TEST")
          expect(response.shadow_ark).to eq("ark:/99999/fk4fn19h88")
        end
      end

      describe "when a shoulder is not given" do
        let(:body) { "success: ark:/99999/fk4fn19h88" }

        context "and the :default_shoulder config option is set" do
          before do
            allow(MintIdentifierRequest).to receive(:execute).with(subject, TEST_ARK_SHOULDER, nil) { stub_response }
            allow(Client.config).to receive(:default_shoulder) { TEST_ARK_SHOULDER }
          end

          it "uses the default shoulder" do
            response = subject.mint_identifier
            expect(response).to be_success
          end
        end

        context "and the :default_shoulder config option is not set" do
          before { allow(Client.config).to receive(:default_shoulder) { nil } }

          it "raises an exception" do
            expect { subject.mint_identifier }.to raise_error(Error)
          end
        end
      end
    end

    describe "#get_identifier_metadata" do
      let(:id) { "ark:/99999/fk4fn19h88" }
      let(:body) do
        <<-EOS
success: ark:/99999/fk4fn19h88
_updated: 1416507086
_target: http://ezid.cdlib.org/id/ark:/99999/fk4fn19h88
_profile: erc
_ownergroup: apitest
_owner: apitest
_export: yes
_created: 1416507086
_status: public
EOS

      end
      let(:stub_response) { GetIdentifierMetadataResponse.new(http_response) }

      before do
        allow(GetIdentifierMetadataRequest).to receive(:execute).with(subject, id) { stub_response }
      end

      it "retrieves the metadata" do
        response = subject.get_identifier_metadata(id)
        expect(response).to be_success
        expect(response.metadata).to eq <<-EOS
_updated: 1416507086
_target: http://ezid.cdlib.org/id/ark:/99999/fk4fn19h88
_profile: erc
_ownergroup: apitest
_owner: apitest
_export: yes
_created: 1416507086
_status: public
EOS
      end
    end

    describe "server status" do
      let(:stub_response) { ServerStatusResponse.new(http_response) }
      let(:body) do
        <<-EOS
success: EZID is up
noid: up
ldap: up
EOS

      end

      before do
        allow(ServerStatusRequest).to receive(:execute).with(subject, "*") { stub_response }
      end

      it "reports the status of EZID and subsystems" do
        response = subject.server_status("*")
        expect(response).to be_success
        expect(response).to be_up
        expect(response.message).to eq("EZID is up")
        expect(response.noid).to eq("up")
        expect(response.ldap).to eq("up")
        expect(response.datacite).to eq("not checked")
      end
    end

    describe "batch download" do
      let(:stub_response) { BatchDownloadResponse.new(http_response) }
      let(:body) { "success: http://ezid.cdlib.org/download/da543b91a0.xml.gz" }

      before do
        allow(BatchDownloadRequest).to receive(:execute).with(subject, format: "xml") { stub_response }
      end

      it "returns the URL to download the batch" do
        response = subject.batch_download(format: "xml")
        expect(response).to be_success
        expect(response.download_url).to eq("http://ezid.cdlib.org/download/da543b91a0.xml.gz")
      end
    end

    describe "error handling" do
      let(:stub_response) { GetIdentifierMetadataResponse.new(http_response) }

      before do
        allow(GetIdentifierMetadataRequest).to receive(:execute).with(subject, "invalid") { stub_response }
      end

      describe "HTTP error response" do
        before do
          allow(http_response).to receive(:value).and_raise(Net::HTTPServerException.new('Barf!', double))
        end

        it "raises an exception" do
          expect { subject.get_identifier_metadata("invalid") }.to raise_error(Net::HTTPServerException)
        end
      end

      describe "EZID API error response" do
        let(:body) { "error: bad request - no such identifier" }

        it "raises an exception" do
          expect { subject.get_identifier_metadata("invalid") }.to raise_error(Error)
        end
      end

      describe "Unexpected response (body)" do
        let(:body) do
          <<-EOS
<html>
  <head>
    <title>Ouch!</title>
  </head>
  <body>
    Help!
  </body>
</html>
EOS

        end

        it "raises an exception" do
          expect { subject.get_identifier_metadata("invalid") }.to raise_error(UnexpectedResponseError)
        end
      end
    end

    describe "retrying on certain errors" do
      before do
        allow(GetIdentifierMetadataResponse).to receive(:new).and_raise(exception)
      end

      describe "HTTP error" do
        let(:exception) { Net::HTTPServerException.new('Barf!', double) }

        it "retries twice" do
          begin
            subject.get_identifier_metadata("invalid")
          rescue Exception => _
          end
          expect(GetIdentifierMetadataResponse).to have_received(:new).exactly(3).times
        end
      end

      describe "Unexpected response" do
        let(:exception) { UnexpectedResponseError.new("HTML?!") }

        it "retries twice" do
          begin
            subject.get_identifier_metadata("invalid")
          rescue Exception => _
          end
          expect(GetIdentifierMetadataResponse).to have_received(:new).exactly(3).times
        end
      end
    end
  end
end
