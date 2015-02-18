module Ezid
  RSpec.describe Client do

    let(:stub_response) { Response.new(http_response) }
    let(:stub_uri) { double }

    describe "initialization without a block" do
      it "should not login" do
        expect_any_instance_of(described_class).not_to receive(:login)
        described_class.new
      end
    end

    describe "#create_identifier" do
      let(:id) { "ark:/99999/fk4fn19h88" }
      let(:http_response) { double(body: "success: ark:/99999/fk4fn19h88") }
      before do
        allow(Requests::CreateIdentifierRequest).to receive(:execute).with(subject, id, nil) { stub_response }
      end
      it "should be a success" do
        response = subject.create_identifier(id)
        expect(response).to be_success
        expect(response.id).to eq(id)
      end
    end

    describe "#mint_identifier" do
      before do
        allow(Requests::MintIdentifierRequest).to receive(:execute).with(subject, TEST_ARK_SHOULDER, nil) { stub_response }
      end
      describe "which is an ARK" do
        let(:http_response) { double(body: "success: ark:/99999/fk4fn19h88") }
        it "should be a success" do
          response = subject.mint_identifier(TEST_ARK_SHOULDER)
          expect(response).to be_success
          expect(response.id).to eq("ark:/99999/fk4fn19h88")
        end
      end
      describe "which is a DOI" do
        let(:http_response) { double(body: "success: doi:10.5072/FK2TEST | ark:/99999/fk4fn19h88") }
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
          allow(Requests::MintIdentifierRequest).to receive(:execute).with(subject, TEST_DOI_SHOULDER, metadata) { stub_response }
        end
        it "should be a sucess" do
          response = subject.mint_identifier(TEST_DOI_SHOULDER, metadata)
          expect(response).to be_success
          expect(response.id).to eq("doi:10.5072/FK2TEST")
          expect(response.shadow_ark).to eq("ark:/99999/fk4fn19h88")
        end
      end
      describe "when a shoulder is not given" do
        let(:http_response) { double(body: "success: ark:/99999/fk4fn19h88") }
        context "and the :default_shoulder config option is set" do
          before do
            allow(Requests::MintIdentifierRequest).to receive(:execute).with(subject, TEST_ARK_SHOULDER, nil) { stub_response } 
            allow(Client.config).to receive(:default_shoulder) { TEST_ARK_SHOULDER }
          end
          it "should use the default shoulder" do
            response = subject.mint_identifier
            expect(response).to be_success
          end
        end
        context "and the :default_shoulder config option is not set" do
          before { allow(Client.config).to receive(:default_shoulder) { nil } }
          it "should raise an exception" do
            expect { subject.mint_identifier }.to raise_error
          end
        end
      end
    end

    describe "#get_identifier_metadata" do
      let(:id) { "ark:/99999/fk4fn19h88" }
      let(:http_response) do
        double(body: <<-EOS
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
                                     )
      end
      before do
        allow(Requests::GetIdentifierMetadataRequest).to receive(:execute).with(subject, id) { stub_response }
      end
      it "should retrieve the metadata" do
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
      let(:stub_response) { Status.new(Response.new(http_response)) }
      let(:http_response) do
        double(body: <<-EOS
success: EZID is up
noid: up
ldap: up
EOS
               )
      end
      before do
        allow(Requests::ServerStatusRequest).to receive(:execute).with(subject, "*") { stub_response }
      end
      it "should report the status of EZID and subsystems" do
        response = subject.server_status("*")
        expect(response).to be_success
        expect(response).to be_up
        expect(response.message).to eq("EZID is up")
        expect(response.noid).to eq("up")
        expect(response.ldap).to eq("up")
        expect(response.datacite).to eq("not checked")
      end
    end

    describe "error handling" do
      let(:http_response) { double(body: "error: bad request - no such identifier") }
      it "should raise an exception" do
        expect { subject.get_identifier_metadata("invalid") }.to raise_error
      end
    end
  end
end
