require 'httparty'
require 'sanitize'

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
      File.open('data/photoblog.json','w'){ |f| f << posts.to_json }
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
