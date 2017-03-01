require 'ezid/batch'

module Ezid
  RSpec.describe Batch do

    let(:batch_file) { File.expand_path("../../fixtures/anvl_batch.txt", __FILE__) }

    subject { described_class.new(:anvl, batch_file) }

    its(:count) { is_expected.to eq 4 }

    specify {
      subject.each do |id|
        expect(id).to be_a(Identifier)
      end
    }

    specify {
      batch_array = subject.to_a
      expect(batch_array.length).to eq 4
    }

    specify {
      ids = subject.map(&:id)
      expect(ids).to eq ["ark:/99999/fk4086hs23", "ark:/99999/fk4086hs23/123", "ark:/99999/fk40p1bb85", "ark:/99999/fk40z7fh7x"]
    }

    specify {
      id = subject.first
      expect(id.target).to eq "http://example.com"
    }

  end
end
