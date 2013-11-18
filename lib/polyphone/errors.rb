module Polyphone
  class Error < ::StandardError; end

  class LastfmRequestError < Error
    attr_reader :code

    def initialize(http_status_code)
      @code = http_status_code
    end
  end
end
