require 'httparty'
require 'sanitize'

module Import
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
