require 'minitest/autorun'
require 'mocha/setup'
require 'bourne'
require 'timecop'

$:.unshift File.dirname(__FILE__) + '../lib'
require 'polyphone'

$:.unshift File.dirname(__FILE__) + '/lib'
require 'polyphone/test_case'
require 'polyphone/test_client'

require 'webmock/minitest'
WebMock.disable_net_connect!
