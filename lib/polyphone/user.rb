module Polyphone
  class User
    include Comparable

    attr_accessor :node
    attr_reader :name

    def initialize(name, client = Client.new)
      @name = name
      @client = client
    end

    def compatibility_with(other_user)
      @client.tasteometer_compare(name, other_user.name)
    end

    def play_count
      attributes['playcount'].to_i
    end

    def <=>(other)
      self.name <=> other.name
    end

    private

    def attributes
      @attributes ||= @client.user_info(name)
    end
  end
end
