require 'httparty'
require 'date'
require 'cgi'
require 'base64'
require 'openssl'
require 'tzinfo'

module Import
  class Withings
    def initialize(consumer_key, consumer_secret, access_token, access_token_secret, user)
      @user = user
      @consumer_key = consumer_key
      @consumer_secret = consumer_secret
      @access_token = access_token
      @access_token_secret = access_token_secret
    end

    def get_steps(time_zone = 'America/New_York')
      today = TZInfo::Timezone.get(time_zone).now
      parameters = 'action=getactivity' +
                   "&oauth_consumer_key=#{@consumer_key}" +
                   "&oauth_nonce=#{rand(100000).to_s}" +
                   '&oauth_signature_method=HMAC-SHA1' +
                   "&oauth_timestamp=#{Time.now.to_i}" +
                   "&oauth_token=#{@access_token}" +
                   '&oauth_version=1.0' +
                   "&date=#{today.strftime("%Y-%m-%d")}" +
                   "&userid=#{@user}"

      base_url = 'https://wbsapi.withings.net/v2/measure'
      signature_base_string = "GET&#{CGI.escape(base_url)}&#{CGI.escape(parameters)}"
      oauth_signature = CGI.escape(Base64.encode64(OpenSSL::HMAC.digest('sha1', "&#{@access_token_secret}", signature_base_string)).chomp)
      url = "#{base_url}?#{parameters}&oauth_signature=#{oauth_signature}"
      response = HTTParty.get(url)
      activities = JSON.parse(response.body)
      withings = {
        :steps => activities['body']['steps'].nil? ? 0 : activities['body']['steps'],
        :distance => activities['body']['distance'].nil? ? 0 : (activities['body']['distance']/1000).round(2)
      }
      File.open('data/withings.json','w'){ |f| f << withings.to_json }
    end
  end
end
