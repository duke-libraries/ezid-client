module Ezid
  #
  # EZID reserved metadata elements
  #
  # @see http://ezid.cdlib.org/doc/apidoc.html#internal-metadata
  #
  module ReservedMetadata
    COOWNERS   = "_coowners".freeze
    CREATED    = "_created".freeze
    DATACENTER = "_datacenter".freeze
    EXPORT     = "_export".freeze
    OWNER      = "_owner".freeze
    OWNERGROUP = "_ownergroup".freeze
    PROFILE    = "_profile".freeze
    SHADOWEDBY = "_shadowedby".freeze
    SHADOWS    = "_shadows".freeze
    STATUS     = "_status".freeze
    TARGET     = "_target".freeze
    UPDATED    = "_updated".freeze

    # Read-only elements
    READONLY = [
      CREATED, DATACENTER, OWNER, OWNERGROUP, SHADOWEDBY, SHADOWS, UPDATED
    ].freeze
  end
end
