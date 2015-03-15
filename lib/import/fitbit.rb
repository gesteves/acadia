require 'oauth'
require 'tzinfo'

module Import
  class Fitbit
    def initialize(consumer_key, consumer_secret, access_token, access_token_secret)
      consumer = OAuth::Consumer.new(consumer_key, consumer_secret, { site: 'https://api.fitbit.com' })
      @access_token = OAuth::AccessToken.new(consumer, access_token, access_token_secret)
    end

    def get_steps(days = 0, time_zone = 'America/New_York')
      today = TZInfo::Timezone.get(time_zone).now - (days * 60 * 60 * 24)
      activities = JSON.parse(@access_token.get("https://api.fitbit.com/1/user/-/activities/date/#{today.strftime("%Y-%m-%d")}.json").body)
      fitbit = {
        :steps => activities['summary']['steps'],
        :distance => activities['summary']['distances'].find{ |d| d['activity'] == 'total' }['distance'],
      }
      File.open('data/fitbit.json','w'){ |f| f << fitbit.to_json }
    end
  end
end
