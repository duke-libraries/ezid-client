module Ezid
  class ProxyIdentifier

    warn "[DEPRECATION] `Ezid::ProxyIdentifier` is deprecated and will be removed in v2.0. Use `Ezid::Identifier` instead. (called from #{caller.first})"

    attr_reader :id
    attr_accessor :__real

    def initialize(id)
      @id = id
      @__real = nil
    end

    protected

    def method_missing(name, *args, &block)
      if __real.nil?
        self.__real = Identifier.find(id)
      end
      __real.send(name, *args, &block)
    end

  end
end
