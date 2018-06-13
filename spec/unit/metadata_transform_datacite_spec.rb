module Ezid
  RSpec.describe MetadataTransformDatacite do
    describe "#transform" do
      before(:each) do
        described_class.transform(test_hash)
      end

      context "when there are no datacite fields" do
        let(:test_hash) { {} }
        let(:expected_xml) { File.read("spec/fixtures/datacite_xml/empty.xml") }

        it "populates a datacite xml field with all required fields as empty" do
          expect(test_hash["datacite"]).to eq(expected_xml)
        end
      end

      context "when there are datacite fields" do
        let(:test_hash) { {
          "datacite.identifier" => "TestIdentifier",
          "datacite.identifiertype" => "TestIdentifierType",
          "datacite.creator" => "TestCreatorName",
          "datacite.title"   => "TestTitle",
          "datacite.publisher" => "TestPublisher",
          "datacite.publicationyear" => "TestPublicationYear",
          "datacite.resourcetype" => "TestResourceType",
          "datacite.resourcetypegeneral" => "TestResourceTypeGeneral",
          "datacite.description" => "TestDescription",
          "some.other.field" => "SomeOtherValue",
        } }
        let(:expected_xml) { File.read("spec/fixtures/datacite_xml/populated.xml") }

        it "populates a datacite xml field using values from the datacite.* fields" do
          expect(test_hash["datacite"]).to eq(expected_xml)
        end

        it "removes the datacite.* fields from the hash" do
          expect(test_hash.keys).not_to include(
            "datacite.identifer",
            "datacite.identifiertype",
            "datacite.creator",
            "datacite.title",
            "datacite.publisher",
            "datacite.publicationyear",
            "datacite.resourcetype",
            "datacite.resourcetypegeneral",
            "datacite.description",
          )
        end

        it "does not remove other fields" do
          expect(test_hash).to include("some.other.field")
        end
      end
    end

    describe "#inverse" do
      let(:test_hash) { {
        "datacite" => test_xml,
        "some.other.field" => "SomeOtherValue"
      } }

      before(:each) do
        described_class.inverse(test_hash)
      end


      context "when there are no datacite fields" do
        let(:expected_hash) { {
          "datacite.identifier" => "",
          "datacite.identifiertype" => "",
          "datacite.creator" => "",
          "datacite.description" => "",
          "datacite.publicationyear" => "",
          "datacite.publisher" => "",
          "datacite.resourcetype" => "",
          "datacite.resourcetypegeneral" => "",
          "datacite.title" => "",
        } }
        let(:test_xml) { File.read("spec/fixtures/datacite_xml/empty.xml") }

        it "populates all required fields as empty" do
          expect(test_hash).to include(expected_hash)
        end
      end

      context "when there are datacite fields" do
        let(:expected_hash) { {
          "datacite.identifier" => "TestIdentifier",
          "datacite.identifiertype" => "TestIdentifierType",
          "datacite.creator" => "TestCreatorName",
          "datacite.title"   => "TestTitle",
          "datacite.publisher" => "TestPublisher",
          "datacite.publicationyear" => "TestPublicationYear",
          "datacite.resourcetype" => "TestResourceType",
          "datacite.resourcetypegeneral" => "TestResourceTypeGeneral",
          "datacite.description" => "TestDescription",
        } }
        let(:test_xml) { File.read("spec/fixtures/datacite_xml/populated.xml") }

        it "populates all fields from the datacite.* fields" do
          expect(test_hash).to include(expected_hash)
        end

        it "removes the datacite field" do
          expect(test_hash).not_to include("datacite")
        end

        it "does not remove other fields" do
          expect(test_hash).to include("some.other.field")
        end
      end
    end

    describe "#transform then #inverse" do
      let(:test_hash) { {
        "datacite.identifier" => "TestIdentifier",
        "datacite.identifiertype" => "TestIdentifierType",
        "datacite.creator" => "TestCreatorName",
        "datacite.title"   => "TestTitle",
        "datacite.publisher" => "TestPublisher",
        "datacite.publicationyear" => "TestPublicationYear",
        "datacite.resourcetype" => "TestResourceType",
        "datacite.resourcetypegeneral" => "TestResourceTypeGeneral",
        "datacite.description" => "TestDescription",
        "some.other.field" => "SomeOtherValue",
      } }

      before(:each) do
        described_class.transform(test_hash)
        described_class.inverse(test_hash)
      end

      it "is a lossless transformation" do
        expect(test_hash).to eq({
          "datacite.identifier" => "TestIdentifier",
          "datacite.identifiertype" => "TestIdentifierType",
          "datacite.creator" => "TestCreatorName",
          "datacite.title"   => "TestTitle",
          "datacite.publisher" => "TestPublisher",
          "datacite.publicationyear" => "TestPublicationYear",
          "datacite.resourcetype" => "TestResourceType",
          "datacite.resourcetypegeneral" => "TestResourceTypeGeneral",
          "datacite.description" => "TestDescription",
          "some.other.field" => "SomeOtherValue",
        })
      end
    end

    describe "#inverse then #transform" do
      let(:test_xml) { File.read("spec/fixtures/datacite_xml/empty.xml") }
      let(:test_hash) { {
        "datacite" => test_xml,
        "some.other.field" => "SomeOtherValue"
      } }

      before(:each) do
        described_class.inverse(test_hash)
        described_class.transform(test_hash)
      end

      it "is a lossless transformation" do
        expect(test_hash).to eq({
          "datacite" => test_xml,
          "some.other.field" => "SomeOtherValue"
        })
      end
    end
  end
end
