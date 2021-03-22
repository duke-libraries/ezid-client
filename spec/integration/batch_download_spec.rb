require 'tempfile'

module Ezid
  RSpec.describe BatchDownload, ezid: true do

    subject do
      a_week_ago = (Time.now - (7*24*60*60)).to_i
      described_class.new(:anvl, compression: "zip", permanence: "test", status: "public", createdAfter: a_week_ago)
    end

    specify {
      expect(subject.download_url).to match(/\Ahttps:\/\/ezid\.cdlib\.org\/download\/\w+\.zip\z/)
      expect(subject.url).to match(/\Ahttps:\/\/ezid\.cdlib\.org\/download\/\w+\.zip\z/)
      Dir.mktmpdir do |tmpdir|
        expect(subject.file(path: tmpdir))
          .to match(/\A#{tmpdir}\/\w+\.zip\z/)
      end
    }

  end
end
