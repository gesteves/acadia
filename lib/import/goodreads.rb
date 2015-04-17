require 'nokogiri'
require 'httparty'

module Import
  class Goodreads
    def initialize(feed, count)
      @feed = feed
      @book_count = count
    end

    def get_books
      books = []
      ['currently-reading', 'read'].each do |shelf|
        books << get_shelf(shelf)
      end
      books = books.flatten.slice(0, @book_count)
      File.open('data/goodreads.json','w'){ |f| f << books.to_json }
    end

    def get_shelf(shelf)
      rss_feed = @feed + "&shelf=#{shelf}"
      books = []
      Nokogiri::XML(HTTParty.get(rss_feed).body).xpath('//channel/item').each do |item|
        book = {
          :id => item.xpath('book_id').first.content,
          :title => item.xpath('title').first.content,
          :author => item.xpath('author_name').first.content,
          :image => item.xpath('book_large_image_url').first.content,
          :url => Nokogiri.HTML(item.xpath('description').first.content).css('a').first['href'],
          :shelf => shelf
        }
        books << book
      end
      books
    end
  end
end
