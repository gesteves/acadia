require 'oauth'
require 'httparty'
require 'RMagick'

module Import
  class Rdio
    def initialize(user_id, consumer_key, consumer_secret, count)
      @user_id = user_id
      @count = count
      @oauth_consumer = OAuth::Consumer.new(consumer_key, consumer_secret, { :site => 'http://api.rdio.com', :scheme => 'header' })
    end

    def get_heavy_rotation
      params = { :method => 'getHeavyRotation', :user => @user_id, :type => 'albums', :friends => false, :count => @count }
      query_string = params.map{ |k,v| "#{URI::escape(k.to_s)}=#{URI::escape(v.to_s)}" }.join('&')
      response = @oauth_consumer.request(:post, '/1/', nil, {}, query_string, { 'Content-Type' => 'application/x-www-form-urlencoded' })
      albums = JSON.parse(response.body)['result']
      Rdio.save_album_images(albums) unless albums.nil?
      File.open('data/rdio.json','w'){ |f| f << albums.to_json }
    end

    def self.save_album_images(albums)
      albums.each do |a|
        album = Magick::Image::from_blob(HTTParty.get(a['icon']).body).first
        sizes = [200, 150, 100, 50]
        sizes.each do |size|
          image = album.resize_to_fill(size, (size * album.rows)/album.columns)
          image.write("source/images/rdio/#{a['key']}_#{size}.jpg"){ self.interlace = Magick::LineInterlace }
        end
      end
    end
  end
end
