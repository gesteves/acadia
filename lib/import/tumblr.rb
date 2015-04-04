require 'httparty'
require 'sanitize'
require 'RMagick'

module Import
  class Photoblog
    def initialize(consumer_key, photo_url, photo_tag, photo_count)
      @consumer_key = consumer_key
      @photo_url    = photo_url
      @photo_tag    = photo_tag
      @photo_count  = photo_count
    end

    def get_photos
      response = HTTParty.get("http://api.tumblr.com/v2/blog/#{@photo_url}/posts/photo?api_key=#{@consumer_key}&tag=#{@photo_tag}&limit=#{@photo_count}")
      posts = JSON.parse(response.body)['response']['posts'].map!{ |p| Photoblog.strip_html(p) }
      Photoblog.save_photos(posts)
      File.open('data/photoblog.json','w'){ |f| f << posts.to_json }
    end

    def self.save_photos(posts)
      posts.each do |post|
        post_id = post['id']
        # Tumblr posts can have more than one photo (photosets),
        # but I'm only interested in showing the first one.
        url = post['photos'][0]['original_size']['url']
        original = Magick::Image::from_blob(HTTParty.get(url).body).first
        sizes = [1280, 693, 558, 526, 498, 484, 470, 416, 334, 278, 249, 242, 235]
        sizes.each do |size|
          image = original.resize_to_fill(size, size)
          image.write("source/images/photoblog/#{post_id}_#{size}.jpg"){ self.interlace = Magick::LineInterlace }
        end
      end
    end

    def self.strip_html(post)
      post[:plain_caption] = post['caption'].nil? ? '' : Sanitize.fragment(post['caption']).strip
      post
    end
  end

  class LinkBlog
    def initialize(consumer_key, link_url, link_tag, link_count)
      @consumer_key = consumer_key
      @link_url     = link_url
      @link_count   = link_count
      @link_tag     = link_tag
    end

    def get_links
      response = HTTParty.get("http://api.tumblr.com/v2/blog/#{@link_url}/posts/link?api_key=#{@consumer_key}&limit=#{@link_count}&tag=#{@link_tag}")
      data = JSON.parse(response.body)
      File.open('data/links.json','w'){ |f| f << data.to_json }
    end
  end
end
