require 'text'

module Import
  class Music
    def initialize(username, api_key, count)
      @api_key = api_key
      @username = username
      @count = count
    end

    def get_latest_artists
      response = HTTParty.get("http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=#{@username}&api_key=#{@api_key}&format=json&limit=200")
      if response.code == 200
        data = JSON.parse(response.body)["recenttracks"]["track"]
        tracks = data
                  .sort { |a,b| artist_count(data, b["artist"]["#text"]) <=> artist_count(data, a["artist"]["#text"]) }
                  .uniq { |t| t["artist"]["#text"] }[0, 5]
                  .map { |t| build_json(data, t["artist"]["#text"]) }
                  .reject(&:nil?)
      end
      tracks.each do |t|
        File.open("source/images/music/#{t[:id]}.jpg",'w'){ |f| f << HTTParty.get(t[:image_url]).body }
      end
      File.open('data/music.json','w'){ |f| f << tracks.to_json }
    end

    def build_json(data, artist_name)
      spotify_data = get_spotify_data(artist_name)
      if spotify_data.nil?
        artist = nil
      else
        artist = {
          name: spotify_data["name"],
          url: spotify_data["external_urls"]["spotify"],
          image_url: spotify_data["images"][0]["url"],
          id: spotify_data["id"],
          plays: artist_count(data, artist_name),
          albums: album_count(data, artist_name)
        }
      end
      artist
    end

    def get_spotify_data(artist)
      response = HTTParty.get("https://api.spotify.com/v1/search?q=artist:#{artist}&type=artist&limit=10")
      File.open("data/#{artist}.json",'w'){ |f| f << response.body }
      artists = JSON.parse(response.body)
      if response.code == 200 && artists["artists"]["total"] > 0
        white = Text::WhiteSimilarity.new
        best_match = artists["artists"]["items"].max { |a, b| white.similarity(a["name"], artist) <=> white.similarity(b["name"], artist) }
      else
        best_match = nil
      end
      best_match
    end

    def artist_count(data, name)
      data.count { |a| a["artist"]["#text"] == name }
    end

    def album_count(data, name)
      data.select { |a| a["artist"]["#text"] == name }.uniq { |t| t["album"]["#text"] }.count
    end
  end
end
