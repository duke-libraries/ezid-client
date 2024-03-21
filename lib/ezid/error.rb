module Ezid
  class Error < ::RuntimeError; end

  # The requested identifier was not found
  class IdentifierNotFoundError < Error; end

  # The requested action is not allowed
  class NotAllowedError < Error; end

  class DeletionError < Error; end

  class UnexpectedResponseError < Error; end

  class ServerError < Error; end
end
