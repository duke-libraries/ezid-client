module Ezid
  class BatchEnumerator
    include Enumerable

    attr_reader :format, :batch_file

    def initialize(format, batch_file)
      @format = format
      @batch_file = batch_file
    end

    def each(&block)
      case format
      when :anvl
        each_anvl &block
      when :xml
        each_xml &block
      when :csv
        each_csv &block
      end
    end

    def each_anvl(&block)
      File.open(batch_file, "rb") do |f|
        while record = f.gets("")
          head, metadata = record.split(/\n/, 2)
          id = head.sub(/\A::/, "").strip
          yield Ezid::Identifier.new(id, metadata: metadata)
        end
      end
    end

    def each_xml
      raise NotImplementedError
    end

    def each_csv
      raise NotImplementedError
    end

  end
end
