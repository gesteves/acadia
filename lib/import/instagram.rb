require 'httparty'
require 'RMagick'

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
      Instagram.save_photos(photos) unless photos.nil?
      File.open('data/instagram.json','w'){ |f| f << photos.to_json }
    end

    def self.save_photos(data)
      data.each do |photo|
        id = photo['id']
        original = Magick::Image::from_blob(HTTParty.get(photo['images']['standard_resolution']['url']).body).first
        sizes = [640, 372, 350, 324, 228, 222, 194, 184, 172, 128, 114, 92, 86, 64]
        sizes.each do |size|
          image = original.resize_to_fit(size)
          image.write("source/images/instagram/#{id}_#{size}.jpg")
        end
      end
    end
  end
end
