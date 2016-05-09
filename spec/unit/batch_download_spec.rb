module Ezid
  RSpec.describe BatchDownload do
    subject { described_class.new(:anvl) }

    describe "#convert_timestamps!" do
      specify {
        expect { subject.convert_timestamps! }
          .to change(subject, :convertTimestamps).to("yes")
      }
    end

    describe "validation" do
      describe "format" do
        describe "nil" do
          it "raises an exception" do
            expect { subject.format = nil }.to raise_error(ArgumentError)
          end
        end
        describe "anvl" do
          specify {
            subject.format = "anvl"
            expect(subject).to be_valid
          }
        end
        describe "xml" do
          specify {
            subject.format = "xml"
            expect(subject).to be_valid
          }
        end
        describe "foo" do
          specify {
            subject.format = "foo"
            expect(subject).to be_invalid
          }
        end
      end
      describe "permanence" do
        describe "nil" do
          specify {
            subject.permanence = nil
            expect(subject).to be_valid
          }
        end
        BatchDownload::PERMANENCE.each do |perm|
          describe perm do
            specify {
              subject.permanence = perm
              expect(subject).to be_valid
            }
          end
        end
        describe "foo" do
          specify {
            subject.permanence = "foo"
            expect(subject).to be_invalid
          }
        end
      end
      describe "crossref" do
        describe "nil" do
          specify {
            subject.crossref = nil
            expect(subject).to be_valid
          }
        end
        describe "yes" do
          specify {
            subject.crossref = "yes"
            expect(subject).to be_valid
          }
        end
        describe "no" do
          specify {
            subject.crossref = "no"
            expect(subject).to be_valid
          }
        end
        describe "foo" do
          specify {
            subject.crossref = "foo"
            expect(subject).to be_invalid
          }
        end
      end
      describe "exported" do
        describe "nil" do
          specify {
            subject.exported = nil
            expect(subject).to be_valid
          }
        end
        describe "yes" do
          specify {
            subject.exported = "yes"
            expect(subject).to be_valid
          }
        end
        describe "no" do
          specify {
            subject.exported = "no"
            expect(subject).to be_valid
          }
        end
        describe "foo" do
          specify {
            subject.exported = "foo"
            expect(subject).to be_invalid
          }
        end
      end
      describe "convertTimestamps" do
        describe "nil" do
          specify {
            subject.convertTimestamps = nil
            expect(subject).to be_valid
          }
        end
        describe "yes" do
          specify {
            subject.convertTimestamps = "yes"
            expect(subject).to be_valid
          }
        end
        describe "no" do
          specify {
            subject.convertTimestamps = "no"
            expect(subject).to be_valid
          }
        end
        describe "foo" do
          specify {
            subject.convertTimestamps = "foo"
            expect(subject).to be_invalid
          }
        end
      end
      describe "type" do
        BatchDownload::TYPES.each do |type|
          describe type do
            specify {
              subject.type = type
              expect(subject).to be_valid
            }
          end
        end
        describe "foo" do
          specify {
            subject.type = "foo"
            expect(subject).to be_invalid
          }
        end
        describe "nil" do
          specify {
            subject.type = nil
            expect(subject).to be_valid
          }
        end
        describe "multi-valued" do
          specify {
            subject.type = [ "ark", "doi" ]
            expect(subject).to be_valid
          }
        end
      end
    end
  end
end
