module Ezid
  RSpec.describe Client do

    describe "initialization without a block" do
      it "should not login" do
        expect_any_instance_of(described_class).not_to receive(:login)
        described_class.new
      end
    end    

    describe "#create_identifier" do
      let(:id) { "ark:/99999/fk4fn19h88" }
      let(:http_response) { double(body: "success: ark:/99999/fk4fn19h88") }
      let(:stub_response) { Response.new(http_response) }
      before do
        allow(Request).to receive(:execute) { stub_response }
      end
      subject { described_class.new.create_identifier(id) }
      it "should be a success" do
        expect(subject).to be_success
        expect(subject.id).to eq(id)
      end
    end

    describe "#mint_identifier" do
      describe "which is an ARK" do
        let(:stub_response) { Response.new(double(body: "success: ark:/99999/fk4fn19h88")) }
        before { allow(Request).to receive(:execute).with(:Post, "/shoulder/#{TEST_ARK_SHOULDER}") { stub_response } }
        subject { described_class.new.mint_identifier(TEST_ARK_SHOULDER) }
        it "should be a succes" do
          expect(subject).to be_success
          expect(subject.id).to eq("ark:/99999/fk4fn19h88")
        end
      end
      describe "which is a DOI" do
        let(:http_response) { double(body: "success: doi:10.5072/FK2TEST | ark:/99999/fk4fn19h88") }
        let(:stub_response) { Response.new(http_response) }
        let(:metadata) do
          <<-EOS
datacite.title: Test
datacite.creator: Duke
datacite.publisher: Duke
datacite.publicationyear: 2014
datacite.resourcetype: Other
EOS
        end
        before { allow(Request).to receive(:execute).with(:Post, "/shoulder/#{TEST_DOI_SHOULDER}") { stub_response } }
        subject { described_class.new.mint_identifier(TEST_DOI_SHOULDER, metadata) }
        it "should be a sucess" do          
          expect(subject).to be_success
          expect(subject.id).to eq("doi:10.5072/FK2TEST")
          expect(subject.shadow_ark).to eq("ark:/99999/fk4fn19h88")
        end
      end
      describe "when a shoulder is not given" do
        let(:stub_response) { Response.new(double(body: "success: ark:/99999/fk4fn19h88")) }
        context "and the :default_shoulder config option is set" do
          subject { described_class.new.mint_identifier }
          before do
            allow(Request).to receive(:execute).with(:Post, "/shoulder/#{TEST_ARK_SHOULDER}") { stub_response } 
            allow(Client.config).to receive(:default_shoulder) { TEST_ARK_SHOULDER }         
          end
          it "should use the default shoulder" do
            expect(subject).to be_success
          end
        end
        context "and the :default_shoulder config option is not set" do
          before { allow(Client.config).to receive(:default_shoulder) { nil } }
          it "should raise an exception" do
            expect { described_class.new.mint_identifier }.to raise_error
          end
        end
      end
    end

    describe "#get_identifier_metadata" do
      let(:stub_response) do
        Response.new(double(body: <<-EOS
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
                                     )) 
      end
      before do
        allow(Request).to receive(:execute) { stub_response }
      end
      subject { described_class.new.get_identifier_metadata("ark:/99999/fk4fn19h88") }
      it "should retrieve the metadata" do
        expect(subject.metadata).to eq <<-EOS
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
      let(:http_response) do
        double(body: <<-EOS
success: EZID is up
noid: up
ldap: up
EOS
               ) 
      end
      let(:stub_response) { Response.new(http_response) }
      before do
        allow(Request).to receive(:execute) { stub_response }
      end
      subject { described_class.new.server_status("*") }
      it "should report the status of EZID and subsystems" do
        expect(subject).to be_success
        expect(subject).to be_up
        expect(subject.message).to eq("EZID is up")
        expect(subject.noid).to eq("up")
        expect(subject.ldap).to eq("up")
        expect(subject.datacite).to eq("not checked")
      end
    end

    describe "error handling" do
      let(:stub_response) { Response.new(body: "error: bad request - no such identifier") }
      before do
        allow(Request).to receive(:execute) { stub_response } 
      end
      it "should raise an exception" do
        expect { subject.get_identifier_metadata("invalid") }.to raise_error
      end
    end
  end
end
