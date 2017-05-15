require 'httparty'
require 'redis'
require 'dotenv'
require 'socket'

module Import
  class WPT
    def initialize(url, key)
      Dotenv.load
      @url = url
      @key = key
      uri = URI.parse(ENV['REDISCLOUD_URL'])
      @redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
    end

    def test_complete?
      latest_test = @redis.get('wpt:test_url')
      request = HTTParty.get(latest_test)
      response = JSON.parse(request.body)
      puts "WPT status #{response['statusCode']}: #{response['statusText']}"
      @redis.del('wpt:test_url') if response['statusCode'] == 400
      response['statusCode'] == 200 && response['statusText'].downcase == 'test complete'
    end

    def active_test?
      @redis.exists('wpt:test_url')
    end

    def request_test
      if active_test? && !test_complete?
        puts 'WPT request skipped; last test not complete'
      else
        url = "http://www.webpagetest.org/runtest.php?url=#{@url}&k=#{@key}&f=json&runs=5&fvonly=1&width=1280&height=800&medianMetric=SpeedIndex"
        request = HTTParty.get(url)
        response = JSON.parse(request.body)
        if response['statusCode'] == 200
          puts "WPT test requested: #{response['data']['userUrl']}"
          @redis.set('wpt:test_url', response['data']['jsonUrl'])
        end
      end
    end

    def save_results
      if active_test? && test_complete?
        wpt = get_latest_result
        results = {
          :speed_index => wpt['data']['median']['firstView']['SpeedIndex'],
          :result_url => wpt['data']['summary']
        }
        result_json = results.to_json
        @redis.set('wpt:test_result', result_json)
      else
        result_json = @redis.get('wpt:test_result')
      end

      unless result_json.nil?
        File.open('data/wpt.json','w'){ |f| f << result_json }
      end
    end

    def get_latest_result
      latest_test = @redis.get('wpt:test_url')
      request = HTTParty.get(latest_test)
      JSON.parse(request.body)
    end
  end
end
