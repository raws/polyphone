module Polyphone
  class Client
    LASTFM_API_KEY = '46c83d236a525d7e6cf38fc201b57235'

    include HTTParty
    base_uri 'https://ws.audioscrobbler.com/2.0'

    attr_accessor :cache, :logger, :min_seconds_between_requests

    def group_members(group_name)
      response = get('group.getmembers', group: group_name)

      response['members']['user'].map do |user|
        User.new(user['name'], self)
      end
    end

    def tasteometer_compare(first_user_name, second_user_name)
      cache_key = tasteometer_compare_cache_key(first_user_name, second_user_name)

      if score = read_from_cache(cache_key)
        score
      else
        response = get('tasteometer.compare', type1: 'user', type2: 'user',
          value1: first_user_name, value2: second_user_name)

        score = response['comparison']['result']['score'].to_f
        write_to_cache(cache_key, score)
        score
      end
    end

    def user_info(user_name)
      cache_key = user_info_cache_key(user_name)

      if attributes = read_from_cache(cache_key)
        attributes
      else
        response = get('user.getinfo', user: user_name)
        attributes = response['user']
        write_to_cache(cache_key, attributes)
        attributes
      end
    end

    private

    def enough_time_elapsed_since_last_request?
      if @last_request_time
        (Time.now - @last_request_time) >= @min_seconds_between_requests
      else
        true
      end
    end

    def get(method_name, params = {})
      params = params_with_defaults(method_name, params)
      wait_until_unthrottled
      log(:debug, "GET /?#{HTTParty::HashConversions.to_params(params)}")
      response = self.class.get('/', query: params)
      @last_request_time = Time.now

      if response.code != 200
        raise LastfmRequestError.new(response.code)
      end

      response
    end

    def log(level, *args)
      if logger
        logger.public_send(level, args.join(' '))
      end
    end

    def params_with_defaults(method_name, params = {})
      {
        api_key: LASTFM_API_KEY,
        format: 'json',
        method: method_name
      }.merge(params)
    end

    def read_from_cache(key)
      if cache
        if value = cache.read(key)
          log(:debug, "Cache hit: #{key.inspect} => #{value.inspect}")
          value
        else
          log(:debug, "Cache miss: #{key.inspect} => nil")
          nil
        end
      end
    end

    def tasteometer_compare_cache_key(*user_names)
      user_names = user_names.map(&:downcase).sort.join('/')
      "tasteometer.compare/#{user_names}"
    end

    def throttled?
      @min_seconds_between_requests && @min_seconds_between_requests > 0
    end

    def user_info_cache_key(user_name)
      "user.getinfo/#{user_name.downcase}"
    end

    def wait_until_unthrottled
      if throttled?
        until enough_time_elapsed_since_last_request?
          sleep @min_seconds_between_requests
        end
      end
    end

    def write_to_cache(key, value)
      if cache
        log(:debug, "Cache write: #{key.inspect} => #{value.inspect}")
        cache.write(key, value)
      end
    end
  end
end
