require 'httparty'

module Import
  class Photoblog
    def initialize(photo_url, photo_tag = nil)
      @photo_url    = photo_url
      @photo_tag    = photo_tag
    end

    def get_photos
      url = @photo_tag.nil? ? "#{@photo_url}/page/1.json" : "#{@photo_url}/tagged/#{@photo_tag}/page/1.json"
      response = HTTParty.get(url, headers: { 'Content-Type' => 'application/vnd.api+json' })
      data = JSON.parse(response.body)
      data['data'].each do |e|
        photo = e['relationships']['photos']['data'][0]
        File.open("source/images/photoblog/#{photo['id']}.jpg",'w'){ |f| f << HTTParty.get(photo['links']['square_840']).body }
      end
      File.open('data/photoblog.json','w'){ |f| f << data.to_json }
    end
  end
end
