require 'text'

module Import
  class Music
    def initialize(refresh_token)
      uri = URI.parse(ENV['REDISCLOUD_URL'])
      @redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
      refresh_token = @redis.get('spotify:refresh_token') || ENV['SPOTIFY_REFRESH_TOKEN']
      @access_token = get_access_token(refresh_token)
    end

    def spotify
      items = []
      ['short_term', 'medium_term', 'long_term'].each do |r|
        items = get_top_artists(r)
        break unless items.empty?
      end
      items = items.slice(0, ENV['SPOTIFY_COUNT'].to_i)
      items.each do |i|
        File.open("source/images/music/#{i[:id]}.jpg",'w'){ |f| f << HTTParty.get(i[:image_url]).body }
      end
      File.open('data/music.json','w'){ |f| f << items.to_json }
    end

    def get_top_artists(time_range)
      url = "https://api.spotify.com/v1/me/top/tracks?limit=50&time_range=#{time_range}"
      response = HTTParty.get(url, headers: { 'Authorization': "Bearer #{@access_token}" })
      items = []
      if response.code == 200
        items = JSON.parse(response.body)['items']
        items = items.group_by { |i| i['album']['name'] }.sort { |k,v| v.size }.map { |k, v| get_spotify_data(v.first) } unless items.empty?
      end
      items
    end

    def get_spotify_data(item)
      {
        id: item['album']['id'],
        name: unclutter_album_name(item['album']['name']),
        url: item['album']['external_urls']['spotify'],
        artist_name: item['artists'][0]['name'],
        image_url: item['album']['images'].sort { |a,b| a['width'] <=> b['width'] }.first['url']
      }
    end

    # Remove shit like [remastered] and (deluxe version) or whatever from album names
    def unclutter_album_name(album)
      album.gsub(/\[[\w\s]+\]/,'').strip.gsub(/\([\w\s-]+\)$/,'').strip
    end

    def get_access_token(refresh_token)
      body = {
        grant_type: 'refresh_token',
        refresh_token: refresh_token,
        redirect_uri: ENV['SITE_URL'],
        client_id: ENV['SPOTIFY_CLIENT_ID'],
        client_secret: ENV['SPOTIFY_CLIENT_SECRET']
      }
      response = HTTParty.post('https://accounts.spotify.com/api/token', body: body)
      if response.code ==  200
        response_body = JSON.parse(response.body)
        @redis.set('spotify:refresh_token', response_body['refresh_token']) unless response_body['refresh_token'].nil?
        access_token = response_body['access_token']
      else
        access_token = nil
      end
      access_token
    end
  end
end
