require 'httparty'

module Import
  class Photoblog
    def initialize(photo_url, photo_count, photo_tag = nil)
      @photo_url    = photo_url
      @photo_tag    = photo_tag
      @photo_count  = photo_count
    end

    def get_photos
      url = @photo_tag.nil? ? "#{@photo_url}/count/#{@photo_count}.json" : "#{@photo_url}/tagged/#{@photo_tag}/count/#{@photo_count}.json"
      response = HTTParty.get(url, headers: { 'Content-Type' => 'application/vnd.api+json' })
      data = JSON.parse(response.body)
      data['data'].each do |e|
        photo = e['relationships']['photos']['data'][0]
        File.open("source/images/photoblog/#{photo['id']}.jpg",'w'){ |f| f << HTTParty.get(photo['links']['large_square']).body }
      end
      File.open('data/photoblog.json','w'){ |f| f << data.to_json }
    end
  end
end
