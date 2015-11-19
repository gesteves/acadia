module Import
  class Music
    def initialize(username, api_key, count)
      @api_key = api_key
      @username = username
      @count = count
    end

    def get_latest_albums
      response = HTTParty.get("http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=#{@username}&api_key=#{@api_key}&format=json&limit=200")
      if response.code == 200
        tracks = JSON.parse(response.body)["recenttracks"]["track"]
                  .uniq! { |t| t["album"]["#text"] }[0, 5]
                  .map!{ |t| get_spotify_data(t["artist"]["#text"],t["album"]["#text"]) }
      end
      File.open('data/music.json','w'){ |f| f << tracks.to_json }
    end

    def get_spotify_data(artist, album)
      response = HTTParty.get("https://api.spotify.com/v1/search?q=artist:#{artist}%20album:#{album}&type=album&limit=1")
      albums = JSON.parse(response.body)
      if response.code == 200 && albums["albums"]["total"] > 0
        {
          artist: artist,
          name: album,
          url: albums["albums"]["items"][0]["external_urls"]["spotify"],
          image_url: albums["albums"]["items"][0]["images"][0]["url"]
        }
      else
        nil
      end
    end
  end
end
