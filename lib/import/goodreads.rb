require 'nokogiri'
require 'RMagick'
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
      save_covers(books)
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

    def save_covers(books)
      books.each do |book|
        cover = Magick::Image::from_blob(HTTParty.get(book[:image]).body).first
        sizes = [150, 100, 50]
        sizes.each do |size|
          image = cover.resize_to_fill(size, (size * cover.rows)/cover.columns)
          image.write("source/images/goodreads/#{book[:id]}_#{size}.jpg"){ self.interlace = Magick::LineInterlace }
        end
      end
    end
  end
end
