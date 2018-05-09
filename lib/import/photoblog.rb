require 'httparty'

module Import
  class Photoblog
    def initialize(url, count = 12)
      @url = url
      @count = count
    end

    def get_photos
      response = HTTParty.get(@url, headers: { 'Content-Type' => 'application/vnd.api+json' })
      data = JSON.parse(response.body)
      data['data'][0, @count].each do |e|
        photo = e['relationships']['photos']['data'][0]
        File.open("source/images/photoblog/#{photo['id']}.jpg",'w'){ |f| f << HTTParty.get(photo['links']['square_824']).body }
      end
      File.open('data/photoblog.json','w'){ |f| f << data.to_json }
    end
  end
end
