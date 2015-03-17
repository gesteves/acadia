require 'httparty'
require 'RMagick'

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
      Untappd.save_beer_labels(checkins)
      File.open('data/untappd.json','w'){ |f| f << checkins.to_json }
    end

    def self.save_beer_labels(checkins)
      checkins.each do |c|
        label = Magick::Image::from_blob(HTTParty.get(c['beer']['beer_label']).body).first
        sizes = [100, 50]
        sizes.each do |size|
          image = label.resize_to_fill(size, (size * label.rows)/label.columns)
          image.write("source/images/untappd/#{c['beer']['bid']}_#{size}.jpg")
        end
      end
    end
  end
end
