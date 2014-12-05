require "delegate"

module Ezid
  RSpec.describe MetadataElements do

    before do
      class TestMetadata < SimpleDelegator
        def initialize
          super(Hash.new)
        end
        include MetadataElements
      end
    end
    after do
      Ezid.remove_const(:TestMetadata)
    end

    describe "reserved reader" do

    end
    
    describe "reserved writer" do

    end

    describe "reserved time reader" do

    end
    
    describe "reserved accessor" do

    end

    describe "profile accessor" do

    end

    describe "element accessor" do

    end

  end
end
