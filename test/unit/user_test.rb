require 'test_helper'

module Polyphone
  class UserTest < TestCase
    def setup
      @user = User.new('rawsosaurus', TestClient.new)

      attributes = { 'playcount' => '105951' }
      @user.stubs attributes: attributes
    end

    test '#<=>' do
      greater_user = User.new('corganon')
      equal_user = User.new('rawsosaurus')
      lesser_user = User.new('wsc')

      assert_equal 1, @user <=> greater_user
      assert_equal 0, @user <=> equal_user
      assert_equal -1, @user <=> lesser_user

      assert_equal @user, equal_user
    end

    test '#compatibility_with' do
      other_user = User.new('corganon')

      assert_equal 0.5, @user.compatibility_with(other_user)
    end

    test '#name' do
      assert_equal 'rawsosaurus', @user.name
    end

    test '#play_count' do
      assert_equal 105951, @user.play_count
    end
  end
end
