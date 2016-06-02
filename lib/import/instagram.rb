require 'httparty'

module Import
  class Instagram
    def initialize(user_id, access_token, count)
      @user_id      = user_id
      @access_token = access_token
      @count        = count
    end

    def get_photos
      response = HTTParty.get("https://api.instagram.com/v1/users/#{@user_id}/media/recent/?access_token=#{@access_token}&count=#{@count}")
      photos = JSON.parse(response.body)['data']
      photos.each do |p|
        File.open("source/images/instagram/#{p['id']}.jpg",'w'){ |f| f << HTTParty.get(p['images']['standard_resolution']['url']).body }
      end
      File.open('data/instagram.json','w'){ |f| f << photos.to_json }
    end
  end
end
