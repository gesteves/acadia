require 'text'

module Import
  class Music
    def initialize(refresh_token)
      uri = URI.parse(ENV['REDISCLOUD_URL'])
      @redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
      refresh_token = @redis.get('spotify:refresh_token') || ENV['SPOTIFY_REFRESH_TOKEN']
      @access_token = get_access_token(refresh_token)
    end

    def get_top_artists
      url = "https://api.spotify.com/v1/me/top/artists?limit=#{ENV['SPOTIFY_COUNT']}&time_range=#{ENV['SPOTIFY_TIME_RANGE']}"
      response = HTTParty.get(url, headers: { 'Authorization': "Bearer #{@access_token}" })
      puts response.body
      if response.code == 200
        items = JSON.parse(response.body)['items']
        items.map! { |i| get_spotify_data(i) }
        items.each do |i|
          File.open("source/images/music/#{i[:id]}.jpg",'w'){ |f| f << HTTParty.get(i[:image_url]).body }
        end
        File.open('data/music.json','w'){ |f| f << items.to_json }
      end
    end

    def get_spotify_data(item)
      {
        id: item['id'],
        name: item['name'],
        url: item['external_urls']['spotify'],
        image_url: item['images'].sort { |a,b| a['width'] <=> b['width'] }.first['url']
      }
    end

    def get_access_token(refresh_token)
      body = {
        grant_type: 'refresh_token',
        refresh_token: refresh_token,
        redirect_uri: 'https://www.gesteves.com',
        client_id: ENV['SPOTIFY_CLIENT_ID'],
        client_secret: ENV['SPOTIFY_CLIENT_SECRET']
      }
      response = HTTParty.post('https://accounts.spotify.com/api/token', body: body)
      puts response.body
      if response.code ==  200
        response_body = JSON.parse(response.body)
        @redis.set('spotify:refresh_token', response_body['refresh_token']) unless response_body['refresh_token'].nil?
        puts "Spotify access token expires in #{response_body['expires_in']} seconds"
        access_token = response_body['access_token']
      else
        access_token = nil
      end
      puts access_token
      access_token
    end
  end
end
