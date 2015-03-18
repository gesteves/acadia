require 'httparty'
require 'redis'
require 'dotenv'

module Import
  class WPT
    def initialize(url, key)
      Dotenv.load
      @url = url
      @key = key
      uri = URI.parse(ENV['REDISCLOUD_URL'])
      @redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
    end

    def request_test
      if @redis.exists('wpt:skip_test')
        puts 'WPT request skipped'
      else
        url = "http://www.webpagetest.org/runtest.php?url=#{@url}&k=#{@key}&f=json"
        request = HTTParty.get(url)
        response = JSON.parse(request.body)
        if response['statusCode'] == 200
          puts "WPT test requested: #{response['data']['userUrl']}"
          @redis.pipelined do
            @redis.set('wpt:test_url', response['data']['jsonUrl'])
            @redis.setex('wpt:skip_test', 60 * 60, 'ok')
          end
        end
      end
    end

    def results
      latest_test = @redis.get('wpt:test_url')
      if latest_test.nil?
        puts 'There are no pending WPT tests.'
      else
        request = HTTParty.get(latest_test)
        response = JSON.parse(request.body)
        if response['statusCode'] == 200 && response['statusText'].downcase == 'test complete'
          result = {
            :speed_index => response['data']['runs']['1']['firstView']['SpeedIndex'],
            :result_url => response['data']['summary']
          }
          File.open('data/wpt.json','w'){ |f| f << result.to_json }
          puts "WPT results stored: #{response['data']['summary']}"
        else
          puts "WPT results not available: #{response['statusText']}"
        end
      end
    end
  end
end
