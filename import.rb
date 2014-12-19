require "oauth"
require "httparty"
require "nokogiri"
require "RMagick"
require "oauth"
require "sanitize"

def get_config
  YAML.load_file("config.yml")
end

def get_tweets
  config = get_config["twitter"]
  consumer_key        = config["consumer_key"]
  consumer_secret     = config["consumer_secret"]
  access_token        = config["access_token"]
  access_token_secret = config["access_token_secret"]
  user                = config["user"]
  count               = config["count"]
  consumer = OAuth::Consumer.new(consumer_key, consumer_secret, { site: "http://api.twitter.com" })
  access_token = OAuth::AccessToken.new(consumer, access_token, access_token_secret)
  response = access_token.get("https://api.twitter.com/1.1/statuses/user_timeline.json?screen_name=#{user}&exclude_replies=true&include_rts=false&trim_user=true&count=200")
  tweets = JSON.parse(response.body).slice(0, count).map!{ |t| expand_tweet(t) }.to_json
  File.open("data/tweets.json","w"){ |f| f << tweets }
end

def get_twitter_user
  config = get_config["twitter"]
  consumer_key        = config["consumer_key"]
  consumer_secret     = config["consumer_secret"]
  access_token        = config["access_token"]
  access_token_secret = config["access_token_secret"]
  user                = config["user"]
  consumer = OAuth::Consumer.new(consumer_key, consumer_secret, { site: "http://api.twitter.com" })
  access_token = OAuth::AccessToken.new(consumer, access_token, access_token_secret)
  response = access_token.get("https://api.twitter.com/1.1/users/show.json?screen_name=#{user}")
  twitter_user = JSON.parse(response.body)
  File.open("data/twitter.json","w"){ |f| f << response.body }
  avatar = Magick::Image::from_blob(HTTParty.get(twitter_user["profile_image_url"].sub("_normal", "")).body).first
  sizes = [200, 150, 100, 50]
  sizes.each do |size|
    image = avatar.resize_to_fill(size, (size * avatar.rows)/avatar.columns)
    image.write("source/images/twitter/#{twitter_user["screen_name"]}_#{size}.jpg")
  end
end

# Horrible method to expand tweet entities (urls, hashtags, mentions, etc.) in tweets
def expand_tweet(tweet)
  text = tweet["text"]
  # Put all the entities into an array and sort them by starting index
  entities = []
  entities += tweet["entities"]["urls"] unless tweet["entities"]["urls"].nil?
  entities += tweet["entities"]["user_mentions"] unless tweet["entities"]["user_mentions"].nil?
  entities += tweet["entities"]["media"] unless tweet["entities"]["media"].nil?
  entities += tweet["entities"]["hashtags"] unless tweet["entities"]["hashtags"].nil?
  entities.sort!{ |a,b| a["indices"].first <=> b["indices"].first } if entities.size > 1
  if entities.empty?
    tweet["expanded_text"] = text
  else
    expanded_text = []
    entities.each_with_index do |e, i|
      # If it's the first entity, start by putting the text from the beginning of the tweet
      # to the start of the entity in the placeholder array
      if i == 0
        end_index = e["indices"].first - 1
        expanded_text << text[0..end_index]
      end

      # Now expand the entity link and place it in the array
      expanded_text << expand_tweet_entity(e)

      # If I'm at the last entity, place the rest of the tweet text in the placeholder array
      if i == entities.size - 1
        start_index = e["indices"].last
        end_index = text.size - 1
        expanded_text << text[start_index..end_index]
      # If not, place the text between the end of the current entity and the start of the next one
      else
        start_index = e["indices"].last
        end_index = entities[i + 1]["indices"].first - 1
        expanded_text << text[start_index..end_index]
      end
    end
    
    # Now join the placeholder array into a string and put it in the tweet object
    tweet["expanded_text"] = expanded_text.join
  end
  # Return the tweet with the new expanded text. Phew.
  tweet
end

# Spit out the correct link tag for each type of entity
def expand_tweet_entity(e)
  if !e["display_url"].nil? && !e["url"].nil?
    link_to(e["display_url"], e["url"])
  elsif !e["screen_name"].nil?
    link_to("@#{e["screen_name"]}", "https://twitter.com/#{e["screen_name"]}")
  elsif !e["text"].nil?
    link_to("##{e["text"]}", "https://twitter.com/hashtag/#{e["text"]}")
  end
end

def link_to(text, url)
  "<a href=\"#{url}\">#{text}</a>"
end


def get_instagram_photos
  config = get_config["instagram"]
  user_id      = config["user_id"]
  consumer_key = config["consumer_key"]
  count        = config["count"]
  response = HTTParty.get("https://api.instagram.com/v1/users/#{user_id}/media/recent/?client_id=#{consumer_key}&count=#{count}")
  photos = JSON.parse(response.body)["data"]
  save_instagram_photos(photos) unless photos.nil?
  File.open("data/instagram.json","w"){ |f| f << photos.to_json }
end

def save_instagram_photos(data)
  data.each do |photo|
    id = photo["id"]
    original = Magick::Image::from_blob(HTTParty.get(photo["images"]["standard_resolution"]["url"]).body).first
    sizes = [640, 320, 240, 200, 160, 140, 120, 100, 80, 60]
    sizes.each do |size|
      image = original.resize_to_fit(size)
      image.write("source/images/instagram/#{id}_#{size}.jpg")
    end
  end
end

def get_photoblog_photos
  config = get_config["tumblr"]
  url          = config["photoblog"]
  consumer_key = config["consumer_key"]
  tag          = config["photo_tag"]
  response = HTTParty.get("http://api.tumblr.com/v2/blog/#{url}/posts/photo?api_key=#{consumer_key}&tag=#{tag}")
  post = JSON.parse(response.body)["response"]["posts"].map!{ |p| update_exif(p) }.map!{ |p| strip_html(p) }.sample
  save_photoblog_photos(post) unless post.nil?
  File.open("data/photoblog.json","w"){ |f| f << post.to_json }
end

def save_photoblog_photos(post)
  post_id = post["id"]
  # Tumblr posts can have more than one photo (photosets),
  # but I'm only interested in showing the first one.
  url = post["photos"][0]["original_size"]["url"]
  original = Magick::Image::from_blob(HTTParty.get(url).body).first
  sizes = [1280, 1200, 1100, 1000, 900, 800, 640, 600, 550, 500, 450, 400, 320]
  sizes.each do |size|
    image = original.resize_to_fill(size, (size * original.rows)/original.columns)
    image.write("source/images/photoblog/#{post_id}_#{size}.jpg")
  end
end

def update_exif(post)
  exif = {}
  film_regex = /^film:name=/i
  lens_regex = /^lens:model=/i
  film = post["tags"].select{ |t| t =~ film_regex }.map{ |t| t.gsub(film_regex, "") }.first
  lens = post["tags"].select{ |t| t =~ lens_regex }.map{ |t| t.gsub(lens_regex, "") }.first
  exif[:camera] = post["photos"][0]["exif"]["Camera"] unless post["photos"][0]["exif"]["Camera"].nil?
  exif[:film]   = film unless film.nil?
  exif[:lens]   = lens unless lens.nil?
  post[:exif] = exif
  post
end

def strip_html(post)
  post[:plain_caption] = post["caption"].nil? ? "" : Sanitize.fragment(post["caption"]).strip
  post
end

def get_tumblr_links
  config = get_config["tumblr"]
  url          = config["links"]
  consumer_key = config["consumer_key"]
  count        = config["links_count"]
  tag          = config["link_tag"]
  response = HTTParty.get("http://api.tumblr.com/v2/blog/#{url}/posts/link?api_key=#{consumer_key}&limit=#{count}&tag=#{tag}")
  data = JSON.parse(response.body)
  File.open("data/links.json","w"){ |f| f << data.to_json }
end

def get_github_repos
  config = get_config["github"]
  access_token = config["access_token"]
  repos = config["repos"]
  repo_array = []
  repos.each do |r|
    owner = r.split('/').first
    name = r.split('/').last
    response = HTTParty.get("https://api.github.com/repos/#{owner}/#{name}?access_token=#{access_token}",
                            headers: { "User-Agent" => "gesteves/farragut" })
    repo_array << JSON.parse(response.body)
  end
  repo_array.sort!{ |a,b| a["name"] <=> b["name"] }
  File.open("data/repos.json","w"){ |f| f << repo_array.to_json }
end

def get_goodreads_data
  config = get_config["goodreads"]
  shelves = config["shelves"]
  count   = config["count"]
  books = []
  shelves.each do |shelf|
    books << import_goodreads_shelf(shelf)
  end
  books = books.flatten.slice(0, count)
  save_book_covers(books)
  File.open("data/goodreads.json","w"){ |f| f << books.to_json }
end

def save_book_covers(books)
  books.each do |book|
    cover = Magick::Image::from_blob(HTTParty.get(book[:image]).body).first
    sizes = [150, 100, 50]
    sizes.each do |size|
      image = cover.resize_to_fill(size, (size * cover.rows)/cover.columns)
      image.write("source/images/goodreads/#{book[:id]}_#{size}.jpg")
    end
  end
end

def import_goodreads_shelf(shelf)
  config = get_config["goodreads"]
  rss_feed = config["rss_feed"] + "&shelf=#{shelf}"
  books = []
  Nokogiri::XML(HTTParty.get(rss_feed).body).xpath("//channel/item").each do |item|
    book = {
      id: item.xpath('book_id').first.content,
      title: item.xpath('title').first.content,
      author: item.xpath('author_name').first.content,
      image: item.xpath('book_large_image_url').first.content,
      url: Nokogiri.HTML(item.xpath('description').first.content).css("a").first["href"],
      shelf: shelf
    }
    books << book
  end
  books
end

def get_untappd_data
  config = get_config["untappd"]
  count         = config["count"]
  username      = config["username"]
  client_id     = config["client_id"]
  client_secret = config["client_secret"]
  checkins = JSON.parse(HTTParty.get("https://api.untappd.com/v4/user/info/#{username}?client_id=#{client_id}&client_secret=#{client_secret}").body)["response"]["user"]["checkins"]["items"].uniq{ |b| b["beer"]["bid"] }.slice(0, count)
  save_beer_labels(checkins)
  File.open("data/untappd.json","w"){ |f| f << checkins.to_json }
end

def save_beer_labels(checkins)
  checkins.each do |c|
    label = Magick::Image::from_blob(HTTParty.get(c["beer"]["beer_label"]).body).first
    sizes = [100, 50]
    sizes.each do |size|
      image = label.resize_to_fill(size, (size * label.rows)/label.columns)
      image.write("source/images/untappd/#{c["beer"]["bid"]}_#{size}.jpg")
    end
  end
end

def get_rdio_data
  config = get_config["rdio"]
  user_id  = config["user_id"]
  count    = config["count"]
  key      = config["key"]
  secret   = config["secret"]
  params = { method: "getHeavyRotation", user: user_id, type: "albums", friends: false, count: count }
  query_string = params.map{ |k,v| "#{URI::escape(k.to_s)}=#{URI::escape(v.to_s)}" }.join("&")
  consumer = OAuth::Consumer.new(key, secret, { site: "http://api.rdio.com", scheme: "header" })
  response = consumer.request(:post, "/1/", nil, {}, query_string, { "Content-Type" => "application/x-www-form-urlencoded" })
  albums = JSON.parse(response.body)["result"]
  save_rdio_images(albums) unless albums.nil?
  File.open("data/rdio.json","w"){ |f| f << albums.to_json }
end

def save_rdio_images(albums)
  albums.each do |a|
    album = Magick::Image::from_blob(HTTParty.get(a["icon"]).body).first
    sizes = [200, 150, 100, 50]
    sizes.each do |size|
      image = album.resize_to_fill(size, (size * album.rows)/album.columns)
      image.write("source/images/rdio/#{a["key"]}_#{size}.jpg")
    end
  end
end