require 'tempfile'

module Ezid
  RSpec.describe BatchDownload do

    subject do
      a_week_ago = (Time.now - (7*24*60*60)).to_i
      described_class.new(:anvl, compression: "zip", permanence: "test", status: "public", createdAfter: a_week_ago)
    end

    its(:download_url) { is_expected.to match(/\Ahttp:\/\/ezid\.cdlib\.org\/download\/\w+\.zip\z/) }

    specify {
      Dir.mktmpdir do |tmpdir|
        expect(subject.download_file(path: tmpdir))
          .to match(/\A#{tmpdir}\/\w+\.zip\z/)
      end
    }

  end
end
