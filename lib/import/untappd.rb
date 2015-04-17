require 'httparty'

module Import
  class Untappd
    def initialize(username, client_id, client_secret, count)
      @username = username
      @client_id = client_id
      @client_secret = client_secret
      @count = count
    end

    def get_beers
      checkins = JSON.parse(HTTParty.get("https://api.untappd.com/v4/user/info/#{@username}?client_id=#{@client_id}&client_secret=#{@client_secret}").body)['response']['user']['checkins']['items'].uniq{ |b| b['beer']['bid'] }.slice(0, @count)
      File.open('data/untappd.json','w'){ |f| f << checkins.to_json }
    end
  end
end
