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
        url = "http://www.webpagetest.org/runtest.php?url=#{@url}&location=ec2-us-east-1:Chrome&k=#{@key}&f=json"
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
          :speed_index => wpt['data']['runs']['1']['firstView']['SpeedIndex'],
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

    def log_results
      if !ENV['HOSTEDGRAPHITE_APIKEY'].nil? && active_test? && test_complete?

        wpt = get_latest_result

        key = ENV['HOSTEDGRAPHITE_APIKEY']
        conn = TCPSocket.new 'carbon.hostedgraphite.com', 2003
        metrics = ''

        unless wpt['data']['runs']['1']['firstView'].nil?
          first_view = wpt['data']['runs']['1']['firstView']
          metrics += key + ".wpt.first_view.speedindex #{first_view['SpeedIndex']}\n"
          metrics += key + ".wpt.first_view.timings.ttfb #{first_view['TTFB']}\n"
          metrics += key + ".wpt.first_view.timings.doc_complete #{first_view['docTime']}\n"
          metrics += key + ".wpt.first_view.timings.fully_loaded #{first_view['fullyLoaded']}\n"
          metrics += key + ".wpt.first_view.timings.visually_complete #{first_view['visualComplete']}\n"
          metrics += key + ".wpt.first_view.timings.render_start #{first_view['render']}\n"
          metrics += key + ".wpt.first_view.bytes.in #{first_view['bytesIn']}\n"
          metrics += key + ".wpt.first_view.bytes.in_doc #{first_view['bytesInDoc']}\n"
          metrics += key + ".wpt.first_view.dom_elements #{first_view['domElements']}\n"
          metrics += key + ".wpt.first_view.responses.200 #{first_view['responses_200']}\n"
          metrics += key + ".wpt.first_view.responses.404 #{first_view['responses_404']}\n"
          metrics += key + ".wpt.first_view.responses.other #{first_view['responses_other']}\n"
        end

        unless wpt['data']['runs']['1']['repeatView'].nil?
          repeat_view = wpt['data']['runs']['1']['repeatView']
          metrics += key + ".wpt.repeat_view.speedindex #{repeat_view['SpeedIndex']}\n"
          metrics += key + ".wpt.repeat_view.timings.ttfb #{repeat_view['TTFB']}\n"
          metrics += key + ".wpt.repeat_view.timings.doc_complete #{repeat_view['docTime']}\n"
          metrics += key + ".wpt.repeat_view.timings.fully_loaded #{repeat_view['fullyLoaded']}\n"
          metrics += key + ".wpt.repeat_view.timings.visually_complete #{repeat_view['visualComplete']}\n"
          metrics += key + ".wpt.repeat_view.timings.render_start #{repeat_view['render']}\n"
          metrics += key + ".wpt.repeat_view.bytes.in #{repeat_view['bytesIn']}\n"
          metrics += key + ".wpt.repeat_view.bytes.in_doc #{repeat_view['bytesInDoc']}\n"
          metrics += key + ".wpt.repeat_view.dom_elements #{repeat_view['domElements']}\n"
          metrics += key + ".wpt.repeat_view.responses.200 #{repeat_view['responses_200']}\n"
          metrics += key + ".wpt.repeat_view.responses.404 #{repeat_view['responses_404']}\n"
          metrics += key + ".wpt.repeat_view.responses.other #{repeat_view['responses_other']}\n"
        end

        conn.puts metrics
        conn.close
      end
    end
  end
end
