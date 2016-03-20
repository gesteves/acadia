require 'httparty'

module Import
  class Instagram
    def initialize(user_id, consumer_key, count)
      @user_id      = user_id
      @consumer_key = consumer_key
      @count        = count
    end

    def get_photos
      response = HTTParty.get("https://api.instagram.com/v1/users/#{@user_id}/media/recent/?client_id=#{@consumer_key}&count=#{@count}")
      photos = JSON.parse(response.body)['data']
      photos.each do |p|
        File.open("source/images/instagram/#{p['id']}.jpg",'w'){ |f| f << HTTParty.get(p['images']['standard_resolution']['url']).body }
      end
      File.open('data/instagram.json','w'){ |f| f << photos.to_json }
    end
  end
end
