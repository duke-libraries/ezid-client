module Ezid
  class Status < SimpleDelegator

    SUBSYSTEMS = %w( noid ldap datacite )

    SUBSYSTEMS.each do |s|
      define_method(s) { subsystems[s] || "not checked" }
    end

    def subsystems
      if content[1]
        content[1].split(/\r?\n/).map { |line| line.split(": ", 2) }.to_h
      else
        {}
      end
    end

    def up?
      success?
    end

  end
end
