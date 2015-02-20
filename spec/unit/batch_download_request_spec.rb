module Ezid
  RSpec.describe BatchDownloadRequest do

    let(:client) { Client.new }
    let(:params) do
      { format: "xml",
        notify: "noreply@example.com",
        convertTimestamps: "yes",
        exported: "no",
        owner: ["you", "me"],
        status: ["reserved", "unavailable"],
        type: "ark"
      }
    end
    subject { described_class.new(client, params) }

    it "should add the request params to the request body" do
      expect(subject.body).to eq("format=xml&notify=noreply%40example.com&convertTimestamps=yes&exported=no&owner=you&owner=me&status=reserved&status=unavailable&type=ark")
    end

    it "should have the correct content type" do
      expect(subject.content_type).to eq("application/x-www-form-urlencoded")
    end

  end
end
