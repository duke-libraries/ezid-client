require "nokogiri"

module Ezid
  class MetadataTransformDatacite

    # Transforms the provided metadata hash into the appropriate format for datacite. Removes all "datacite.*" keys
    # and transforms these to the appropriate datacite xml. The resultant xml is then added to a single "datacite" key.
    def self.transform(hsh)
      # Render the datacite xml
      resource_opts = {
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "xmlns" => "http://datacite.org/schema/kernel-4",
        "xsi:schemaLocation" => "http://datacite.org/schema/kernel-4 http://schema.datacite.org/meta/kernel-4.5/metadata.xsd"
      }
      xml_builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") { |builder|
        builder.resource(resource_opts) {
          builder.identifier(identifierType: hsh["datacite.identifiertype"] || "DOI") {
            builder.text hsh["datacite.identifier"]
          }
          builder.creators {
            builder.creator {
              builder.creatorName hsh["datacite.creator"]
            }
          }
          builder.titles {
            builder.title hsh["datacite.title"]
          }
          builder.publisher hsh["datacite.publisher"]
          builder.publicationYear hsh["datacite.publicationyear"]
          builder.resourceType(resourceTypeGeneral: hsh["datacite.resourcetypegeneral"]) {
            builder.text hsh["datacite.resourcetype"]
          }
          builder.descriptions {
            builder.description(descriptionType: "Abstract") {
              builder.text hsh["datacite.description"]
            }
          }
        }
      }
      # Using this save option to prevent NG from rendering new lines and tabs
      # between nodes. This to help with a cleaner anvl conversion. Similarly,
      # the sub should just remove the new line after the xml header that NG
      # adds, ex:
      #   <?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<resource ...
      xml = xml_builder
        .to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
        .sub("\n", "")


      # Transform the hash
      hsh.reject! { |k, v| k =~ /^datacite\./ }
      hsh["datacite"] = xml
    end

    # Transforms the provided datacite metadata hash into the format appropriate for the Metadata class.
    # Extracts appropriate fields from the datacite xml and creates the corresponding "datacite.*" keys
    def self.inverse(hsh)
      xml = Nokogiri::XML(hsh["datacite"])
      xmlns = "http://datacite.org/schema/kernel-4"
      hsh["datacite.identifier"] = xml.at_xpath("/ns:resource/ns:identifier/text()", ns: xmlns).to_s
      hsh["datacite.identifiertype"] = xml.at_xpath("/ns:resource/ns:identifier/attribute::identifierType", ns: xmlns).to_s
      hsh["datacite.creator"] = xml.at_xpath("/ns:resource/ns:creators/ns:creator/ns:creatorName/text()", ns: xmlns).to_s
      hsh["datacite.title"] = xml.at_xpath("/ns:resource/ns:titles/ns:title/text()", ns: xmlns).to_s
      hsh["datacite.publisher"] = xml.at_xpath("/ns:resource/ns:publisher/text()", ns: xmlns).to_s
      hsh["datacite.publicationyear"] = xml.at_xpath("/ns:resource/ns:publicationYear/text()", ns: xmlns).to_s
      hsh["datacite.resourcetype"] = xml.at_xpath("/ns:resource/ns:resourceType/text()", ns: xmlns).to_s
      hsh["datacite.resourcetypegeneral"] = xml.at_xpath("/ns:resource/ns:resourceType/attribute::resourceTypeGeneral", ns: xmlns).to_s
      hsh["datacite.description"] = xml.at_xpath("/ns:resource/ns:descriptions/ns:description/text()", ns: xmlns).to_s
      hsh.delete("datacite")
    end
  end
end
