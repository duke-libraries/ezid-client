module Ezid
  RSpec.describe "proxy identifier", deprecated: true do
    require 'ezid/proxy_identifier'
    describe ProxyIdentifier do
      describe "initialization" do
        it "should not load the real identifier" do
          expect(Identifier).not_to receive(:find)
          described_class.new("ark:/99999/fk4fn19h88")
        end
      end

      describe "lazy loading" do
        subject { described_class.new(id) }

        let(:id) { "ark:/99999/fk4fn19h88" }
        let(:real) { double(id: id, target: "http://ezid.cdlib.org/id/#{id}") }

        it "should load the real identifier when calling a missing method" do
          expect(Identifier).to receive(:find).with(id) { real }
          expect(subject.target).to eq(real.target)
        end
      end
    end
  end
end
