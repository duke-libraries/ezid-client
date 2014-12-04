module Ezid
  RSpec.describe Client do

    describe "initialization" do
      describe "without a block" do
        it "should not open a session" do
          expect(subject.session).not_to be_open
        end
      end
      describe "with a block" do
        let(:stub_login) { Response.new(double(body: "success: session cookie return")) }
        let(:stub_logout) { Response.new(double(body: "success: authentication credentials flushed")) }
        before do
          allow(Request).to receive(:execute).with(:Get, "/login") { stub_login }
          allow(Request).to receive(:execute).with(:Get, "/logout") { stub_logout }
          allow(stub_login).to receive(:cookie) { "cookie" }
        end
        it "should wrap the block in a session" do
          described_class.new do |client|
            expect(client.session).to be_open
          end
        end
      end
    end    

    describe "authentication" do
      describe "#login" do
        let(:stub_login) { Response.new(double(body: "success: session cookie return")) }
        before do
          allow(Request).to receive(:execute).with(:Get, "/login") { stub_login }
          allow(stub_login).to receive(:cookie) { "cookie" }
        end
        it "should open a session" do
          expect(subject.session).to be_closed
          subject.login
          expect(subject.session).to be_open
        end
      end
      describe "#logout" do
        before do
          subject.login
        end
        it "should close the session" do
          expect(subject.session).to be_open
          subject.logout
          expect(subject.session).to be_closed
        end
      end
      describe "without a session" do
        it "should send the user name and password"
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
      before { allow(Request).to receive(:execute) { stub_response } }
      describe "which is an ARK" do
        let(:stub_response) { Response.new(double(body: "success: ark:/99999/fk4fn19h88")) }
        subject { described_class.new.mint_identifier(ARK_SHOULDER) }
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
        subject { described_class.new.mint_identifier(DOI_SHOULDER, metadata) }
        it "should be a sucess" do          
          expect(subject).to be_success
          expect(subject.id).to eq("doi:10.5072/FK2TEST")
          expect(subject.shadow_ark).to eq("ark:/99999/fk4fn19h88")
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

    describe "#modify_identifier", type: :feature do
      before do
        @id = described_class.new.mint_identifier(ARK_SHOULDER).id
      end
      subject { described_class.new.modify_identifier(@id, "dc.title" => "Test") }
      it "should update the metadata" do
        expect(subject).to be_success
        response = described_class.new.get_identifier_metadata(@id)
        expect(response.metadata).to match(/dc.title: Test/)
      end
    end

    describe "#delete_identifier", type: :feature do
      before do
        @id = described_class.new.mint_identifier(ARK_SHOULDER, "_status" => "reserved").id
      end
      subject { described_class.new.delete_identifier(@id) }
      it "should delete the identifier" do
        expect(subject).to be_success
        expect { described_class.new.get_identifier_metadata(@id) }.to raise_error
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
