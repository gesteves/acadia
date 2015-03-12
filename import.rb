require "oauth"
require "httparty"
require "nokogiri"
require "RMagick"
require "oauth"
require "sanitize"
require "dotenv"

Dotenv.load

def get_fitbit_data
  consumer_key        = ENV["FITBIT_CONSUMER_KEY"]
  consumer_secret     = ENV["FITBIT_CONSUMER_SECRET"]
  access_token        = ENV["FITBIT_ACCESS_TOKEN"]
  access_token_secret = ENV["FITBIT_ACCESS_TOKEN_SECRET"]
  user_id             = ENV["FITBIT_USER_ID"]
  consumer = OAuth::Consumer.new(consumer_key, consumer_secret, { site: "https://api.fitbit.com" })
  access_token = OAuth::AccessToken.new(consumer, access_token, access_token_secret)
  profile = JSON.parse(access_token.get("https://api.fitbit.com/1/user/#{user_id}/profile.json").body)
  offset_from_utc = offset_from_utc(profile["user"]["offsetFromUTCMillis"].to_f)
  today = Time.now.getlocal(offset_from_utc)
  activities = JSON.parse(access_token.get("https://api.fitbit.com/1/user/-/activities/date/#{today.strftime("%Y-%m-%d")}.json").body)
  sleep = JSON.parse(access_token.get("https://api.fitbit.com/1/user/-/sleep/date/#{today.strftime("%Y-%m-%d")}.json").body)
  fitbit = {
    :steps => activities["summary"]["steps"],
    :distance => activities["summary"]["distances"].find{ |d| d["activity"] == "total" }["distance"],
    :sleep => sleep["summary"]["totalMinutesAsleep"]
  }
  File.open("data/fitbit.json","w"){ |f| f << fitbit.to_json }
end

def offset_from_utc(milliseconds)
  seconds = milliseconds/1000
  minutes = (seconds / 60) % 60
  hours = seconds / (60 * 60)
  format("%+03d:%02d", hours, minutes)
end

def get_tweets
  consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
  consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
  access_token        = ENV["TWITTER_ACCESS_TOKEN"]
  access_token_secret = ENV["TWITTER_ACCESS_TOKEN_SECRET"]
  user                = ENV["TWITTER_USER"]
  count               = ENV["TWITTER_COUNT"].to_i
  consumer = OAuth::Consumer.new(consumer_key, consumer_secret, { site: "http://api.twitter.com" })
  access_token = OAuth::AccessToken.new(consumer, access_token, access_token_secret)
  response = access_token.get("https://api.twitter.com/1.1/statuses/user_timeline.json?screen_name=#{user}&exclude_replies=true&include_rts=false&trim_user=true&count=200")
  tweets = JSON.parse(response.body).slice(0, count).map!{ |t| expand_tweet(t) }.to_json
  File.open("data/tweets.json","w"){ |f| f << tweets }
end

def get_twitter_user
  consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
  consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
  access_token        = ENV["TWITTER_ACCESS_TOKEN"]
  access_token_secret = ENV["TWITTER_ACCESS_TOKEN_SECRET"]
  user                = ENV["TWITTER_USER"]
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
  user_id      = ENV["INSTAGRAM_USER_ID"]
  consumer_key = ENV["INSTAGRAM_CONSUMER_KEY"]
  count        = ENV["INSTAGRAM_COUNT"].to_i
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
  posts = call_photoblog_api
  post = posts.map!{ |p| update_exif(p) }.map!{ |p| strip_html(p) }.sample
  save_photoblog_photos(post) unless post.nil?
  File.open("data/photoblog.json","w"){ |f| f << post.to_json }
end

def call_photoblog_api(offset = 0, limit = 20)
  posts = []
  url          = ENV["TUMBLR_PHOTOBLOG"]
  consumer_key = ENV["TUMBLR_CONSUMER_KEY"]
  tag          = ENV["TUMBLR_PHOTO_TAG"]
  response = HTTParty.get("http://api.tumblr.com/v2/blog/#{url}/posts/photo?api_key=#{consumer_key}&tag=#{tag}&offset=#{offset}&limit=#{limit}")
  body = JSON.parse(response.body)
  posts << body["response"]["posts"]
  if body["response"]["total_posts"] > offset + limit
    posts << call_photoblog_api(offset + limit, limit)
  end
  posts.flatten
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
  url          = ENV["TUMBLR_LINKS"]
  consumer_key = ENV["TUMBLR_CONSUMER_KEY"]
  count        = ENV["TUMBLR_LINKS_COUNT"].to_i
  tag          = ENV["TUMBLR_LINK_TAG"]
  response = HTTParty.get("http://api.tumblr.com/v2/blog/#{url}/posts/link?api_key=#{consumer_key}&limit=#{count}&tag=#{tag}")
  data = JSON.parse(response.body)
  File.open("data/links.json","w"){ |f| f << data.to_json }
end

def get_github_repos
  access_token = ENV["GITHUB_ACCESS_TOKEN"]
  repos = YAML.load_file("data/content.yml")["repos"]
  repo_array = []
  repos.each do |r|
    owner = r.split('/').first
    name = r.split('/').last
    response = HTTParty.get("https://api.github.com/repos/#{owner}/#{name}?access_token=#{access_token}",
                            headers: { "User-Agent" => "gesteves/acadia" })
    repo_array << JSON.parse(response.body)
  end
  repo_array.sort!{ |a,b| a["name"] <=> b["name"] }
  File.open("data/repos.json","w"){ |f| f << repo_array.to_json }
end

def get_total_commits(days = 30)
  commits = {
    :total_commits => 0,
    :additions => 0,
    :deletions => 0
  }
  pushes = get_push_events(Time.now - (60*60*24*days))
  pushes.each do |p|
    commits[:total_commits] += p["payload"]["distinct_size"]
    p["payload"]["commits"].find_all{ |c| c["distinct"] }.each do |c|
      stats = get_commit_stats(c["url"])
      unless stats.nil?
        commits[:additions] += stats["additions"]
        commits[:deletions] += stats["deletions"]
      end
    end
  end
  File.open("data/commits.json","w"){ |f| f << commits.to_json }
end

def get_push_events(oldest, page = 1)
  access_token = ENV["GITHUB_ACCESS_TOKEN"]
  events = JSON.parse(HTTParty.get("https://api.github.com/users/gesteves/events?access_token=#{access_token}&page=#{page}",
                      headers: { "User-Agent" => "gesteves/acadia" }).body)
  pushes = events.find_all{ |e| e["type"] == "PushEvent" && Time.parse(e["created_at"]) >= oldest }
  if page < 10 && (pushes.nil? || pushes.size == 0 || Time.parse(pushes.last["created_at"]) > oldest)
    pushes += get_push_events(oldest, page + 1)
  end
  pushes
end

def get_commit_stats(url)
  access_token = ENV["GITHUB_ACCESS_TOKEN"]
  commit = JSON.parse(HTTParty.get("#{url}?access_token=#{access_token}",
                      headers: { "User-Agent" => "gesteves/acadia" }).body)
  commit["stats"]
end

def get_goodreads_data
  shelves = ["currently-reading", "read"]
  count   = ENV["GOODREADS_COUNT"].to_i
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
  rss_feed = ENV["GOODREADS_RSS_FEED"] + "&shelf=#{shelf}"
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
  count         = ENV["UNTAPPD_COUNT"].to_i
  username      = ENV["UNTAPPD_USERNAME"]
  client_id     = ENV["UNTAPPD_CLIENT_ID"]
  client_secret = ENV["UNTAPPD_CLIENT_SECRET"]
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
  user_id  = ENV["RDIO_USER_ID"]
  count    = ENV["RDIO_COUNT"].to_i
  key      = ENV["RDIO_KEY"]
  secret   = ENV["RDIO_SECRET"]
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