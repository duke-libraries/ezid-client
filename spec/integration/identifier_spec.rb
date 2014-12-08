module Ezid
  RSpec.describe Identifier do

    it "should handle CRUD operations" do
      # mint
      minted = described_class.create(shoulder: ARK_SHOULDER)
      expect(minted.status).to eq("public")
      # create
      created = described_class.create(id: "#{minted}/123")
      expect(created.id).to eq("#{minted}/123")
      # update
      minted.target = "http://example.com"
      minted.save
      # retrieve
      retrieved = described_class.find(minted.id)
      expect(retrieved.target).to eq("http://example.com")
      # delete
      reserved = described_class.create(shoulder: ARK_SHOULDER, status: "reserved")
      reserved.delete
      expect { described_class.find(reserved.id) }.to raise_error
    end

  end
end
