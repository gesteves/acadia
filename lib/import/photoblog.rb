require 'httparty'

module Import
  class Photoblog
    def initialize(photo_url, photo_tag, photo_count)
      @photo_url    = photo_url
      @photo_tag    = photo_tag
      @photo_count  = photo_count
    end

    def get_photos
      response = HTTParty.get("#{@photo_url}/tagged/#{@photo_tag}/count/#{@photo_count}.json")
      posts = JSON.parse(response.body)['entries']
      File.open('data/photoblog.json','w'){ |f| f << posts.to_json }
    end
  end
end
