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
        data = JSON.parse(response.body)["recenttracks"]["track"]
        tracks = data
                  .sort { |a,b| album_count(data, b["album"]["#text"]) <=> album_count(data, a["album"]["#text"]) }
                  .uniq { |t| t["album"]["#text"] }[0, 5]
                  .map { |t| get_spotify_data(t["artist"]["#text"],t["album"]["#text"]) }
      end
      File.open('data/music.json','w'){ |f| f << tracks.to_json }
    end

    def get_spotify_data(artist, album)
      response = HTTParty.get("https://api.spotify.com/v1/search?q=artist:#{artist}%20album:#{album}&type=album&limit=1")
      albums = JSON.parse(response.body)
      if response.code == 200 && albums["albums"]["total"] > 0
        {
          artist: artist,
          name: unclutter_album_name(album),
          url: albums["albums"]["items"][0]["external_urls"]["spotify"],
          image_url: albums["albums"]["items"][0]["images"][0]["url"]
        }
      else
        nil
      end
    end

    # Remove shit like [remastered] and (deluxe version) or whatever from album names
    def unclutter_album_name(album)
      album.gsub(/\[[\w\s]+\]/,'').strip.gsub(/\([\w\s-]+\)$/,'').strip
    end

    def album_count(data, name)
      data.count { |a| a["album"]["#text"] == name }
    end
  end
end
