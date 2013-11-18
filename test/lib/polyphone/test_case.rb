module Polyphone
  class TestCase < MiniTest::Unit::TestCase
    def self.test(name, &block)
      define_method "test #{name.inspect}", &block
    end

    private

    def fixture(name)
      path = File.dirname(__FILE__) + "/../../fixtures/#{name}"

      File.open(path, 'r') do |io|
        io.read
      end
    end
  end
end
