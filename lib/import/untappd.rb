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
      checkins.each do |c|
        url = c['beer']['beer_label'] =~ /badge-beer-default/ ? c['brewery']['brewery_label'] : c['beer']['beer_label']
        File.open("source/images/untappd/#{c['beer']['bid']}.jpg",'w'){ |f| f << HTTParty.get(url).body }
      end
      File.open('data/untappd.json','w'){ |f| f << checkins.to_json }
    end
  end
end
