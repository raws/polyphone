require 'test_helper'

module Polyphone
  class ClientTest < TestCase
    LASTFM_BASE_URI = 'https://ws.audioscrobbler.com/2.0/'

    def setup
      @client = Client.new
    end

    test '#group_members with a successful response' do
      stub_request(:get, LASTFM_BASE_URI).
        with(query: params(method: 'group.getmembers', group: 'thelevelup')).
        to_return(body: fixture('group.members.json'),
          headers: { 'Content-Type' => 'application/json' }, status: 200)

      users = @client.group_members('thelevelup')
      assert_equal 16, users.size

      users.each do |user|
        assert user.name, "expected #{user.inspect} to have a name"
      end
    end

    test '#group_members when Last.fm responds with an error' do
      stub_request(:get, LASTFM_BASE_URI).
        with(query: params(method: 'group.getmembers', group: 'thelevelup')).
        to_return(status: 400)

      assert_raises(LastfmRequestError) do
        @client.group_members('thelevelup')
      end
    end

    test '#tasteometer_compare with a successful response' do
      stub_tasteometer_compare_request 'rawsosaurus', 'corganon'

      score = @client.tasteometer_compare('rawsosaurus', 'corganon')
      assert_equal 0.23987704515457, score
    end

    test '#tasteometer_compare with a cache' do
      response = mock_response('tasteometer.compare.json')
      @client.class.expects(:get).once.returns(response)

      expected_cache_key = 'tasteometer.compare/corganon/rawsosaurus'
      expected_score = 0.23987704515457

      cache = mock('cache') do
        expects(:read).once.with(expected_cache_key).returns(nil)
        expects(:write).once.with(expected_cache_key, expected_score).returns(true)
        expects(:read).once.with(expected_cache_key).returns(expected_score)
      end

      @client.cache = cache

      2.times do
        score = @client.tasteometer_compare('rawsosaurus', 'corganon')
        assert_equal expected_score, score
      end
    end

    test '#tasteometer_compare when Last.fm responds with an error' do
      stub_request(:get, LASTFM_BASE_URI).
        with(query: params(method: 'tasteometer.compare', type1: 'user',
          type2: 'user', value1: 'rawsosaurus', value2: 'corganon')).
        to_return(status: 400)

      assert_raises(LastfmRequestError) do
        @client.tasteometer_compare('rawsosaurus', 'corganon')
      end
    end

    test '#user_info with a successful response' do
      stub_request(:get, LASTFM_BASE_URI).
        with(query: params(method: 'user.getinfo', user: 'rawsosaurus')).
        to_return(body: fixture('user.getinfo.json'),
          headers: { 'Content-Type' => 'application/json' }, status: 200)

      attributes = @client.user_info('rawsosaurus')

      assert_equal 'rawsosaurus', attributes['name']
      assert_equal '105951', attributes['playcount']
    end

    test '#user_info with a cache' do
      response = mock_response('user.getinfo.json')
      @client.class.expects(:get).once.returns(response)

      expected_cache_key = 'user.getinfo/rawsosaurus'
      expected_attributes = JSON.parse(fixture('user.getinfo.json'))['user']

      cache = mock('cache') do
        expects(:read).once.with(expected_cache_key).returns(nil)
        expects(:write).once.with(expected_cache_key, expected_attributes).returns(true)
        expects(:read).once.with(expected_cache_key).returns(expected_attributes)
      end

      @client.cache = cache

      2.times do
        attributes = @client.user_info('rawsosaurus')
        assert_equal expected_attributes, attributes
      end
    end

    test '#user_info when Last.fm responds with an error' do
      stub_request(:get, LASTFM_BASE_URI).
        with(query: params(method: 'user.getinfo', user: 'rawsosaurus')).
        to_return(status: 400)

      assert_raises(LastfmRequestError) do
        @client.user_info('rawsosaurus')
      end
    end

    private

    def mock_response(fixture_name)
      parsed_fixture = JSON.parse(fixture(fixture_name))
      parsed_fixture.stubs code: 200
      parsed_fixture
    end

    def params(extra_params = {})
      { api_key: Client::LASTFM_API_KEY, format: 'json' }.merge(extra_params)
    end

    def stub_tasteometer_compare_request(first_user_name, second_user_name)
      stub_request(:get, LASTFM_BASE_URI).
        with(query: params(method: 'tasteometer.compare', type1: 'user',
          type2: 'user', value1: first_user_name, value2: second_user_name)).
        to_return(body: fixture('tasteometer.compare.json'),
          headers: { 'Content-Type' => 'application/json' }, status: 200)
    end
  end
end
