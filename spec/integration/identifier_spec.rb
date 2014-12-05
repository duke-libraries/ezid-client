module Ezid
  RSpec.describe Identifier do

    it "should handle CRUD operations" do
      # create (mint)
      identifier = described_class.create(shoulder: ARK_SHOULDER)
      expect(identifier.status).to eq("public")
      # update
      identifier.target = "http://example.com"
      identifier.save
      # retrieve
      identifier = described_class.find(identifier.id)
      expect(identifier.target).to eq("http://example.com")
      # delete
      identifier = described_class.create(shoulder: ARK_SHOULDER, status: "reserved")
      identifier.delete
      expect { described_class.find(identifier.id) }.to raise_error
    end

  end
end
