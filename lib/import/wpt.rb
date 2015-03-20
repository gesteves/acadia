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

    def request_test
      if @redis.exists('wpt:skip_test')
        puts 'WPT request skipped'
      elsif !test_complete?
        puts 'WPT request skipped; last test not complete'
      else
        url = "http://www.webpagetest.org/runtest.php?url=#{@url}&k=#{@key}&f=json"
        request = HTTParty.get(url)
        response = JSON.parse(request.body)
        if response['statusCode'] == 200
          puts "WPT test requested: #{response['data']['userUrl']}"
          @redis.pipelined do
            @redis.set('wpt:test_url', response['data']['jsonUrl'])
            @redis.setex('wpt:skip_test', 60 * 59, 'ok')
          end
        end
      end
    end

    def test_complete?
      latest_test = @redis.get('wpt:test_url')
      if latest_test.nil?
        true
      else
        request = HTTParty.get(latest_test)
        response = JSON.parse(request.body)
        response['statusCode'] == 200 && response['statusText'].downcase == 'test complete'
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
          log(response['data'])
          result = {
            :speed_index => response['data']['runs']['1']['firstView']['SpeedIndex'],
            :result_url => response['data']['summary']
          }
          result = result.to_json
          @redis.set('wpt:test_result', result)
          puts "WPT results stored: #{response['data']['summary']}"
        else
          result = @redis.get('wpt:test_result')
          puts "WPT results not available: #{response['statusText']}"
        end

        unless result.nil?
          File.open('data/wpt.json','w'){ |f| f << result }
        end
      end
    end

    def log(data)
      unless ENV['HOSTEDGRAPHITE_APIKEY'].nil?
        key = ENV['HOSTEDGRAPHITE_APIKEY']
        conn   = TCPSocket.new 'carbon.hostedgraphite.com', 2003
        metrics = ""

        unless data['runs']['1']['firstView'].nil?
          metrics += key + ".wpt.first_view.speed_index #{data['runs']['1']['firstView']['SpeedIndex']}\n"
          metrics += key + ".wpt.first_view.load_time #{data['runs']['1']['firstView']['loadTime']}\n"
          metrics += key + ".wpt.first_view.ttfb #{data['runs']['1']['firstView']['TTFB']}\n"
          metrics += key + ".wpt.first_view.start_render #{data['runs']['1']['firstView']['render']}\n"
          metrics += key + ".wpt.first_view.doc_complete #{data['runs']['1']['firstView']['docTime']}\n"
          metrics += key + ".wpt.first_view.doc_bytes_in #{data['runs']['1']['firstView']['bytesInDoc']}\n"
          metrics += key + ".wpt.first_view.fully_loaded #{data['runs']['1']['firstView']['fullyLoaded']}\n"
          metrics += key + ".wpt.first_view.full_bytes_in #{data['runs']['1']['firstView']['bytesInDoc']}\n"
          metrics += key + ".wpt.first_view.visually_complete #{data['runs']['1']['firstView']['visualComplete']}\n"
        end

        unless data['runs']['1']['repeatView'].nil?
          metrics += key + ".wpt.repeat_view.speed_index #{data['runs']['1']['repeatView']['SpeedIndex']}\n"
          metrics += key + ".wpt.repeat_view.load_time #{data['runs']['1']['repeatView']['loadTime']}\n"
          metrics += key + ".wpt.repeat_view.ttfb #{data['runs']['1']['repeatView']['TTFB']}\n"
          metrics += key + ".wpt.repeat_view.start_render #{data['runs']['1']['repeatView']['render']}\n"
          metrics += key + ".wpt.repeat_view.doc_complete #{data['runs']['1']['repeatView']['docTime']}\n"
          metrics += key + ".wpt.repeat_view.doc_bytes_in #{data['runs']['1']['repeatView']['bytesInDoc']}\n"
          metrics += key + ".wpt.repeat_view.fully_loaded #{data['runs']['1']['repeatView']['fullyLoaded']}\n"
          metrics += key + ".wpt.repeat_view.full_bytes_in #{data['runs']['1']['repeatView']['bytesInDoc']}\n"
          metrics += key + ".wpt.repeat_view.visually_complete #{data['runs']['1']['repeatView']['visualComplete']}\n"
        end

        conn.puts metrics
        conn.close
      end
    end
  end
end
