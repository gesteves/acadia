require "oauth"
require "httparty"
require "nokogiri"

def get_config
  YAML.load_file("config.yml")
end

def get_tweets
  begin
    config = get_config["twitter"]
    consumer_key        = config["consumer_key"]
    consumer_secret     = config["consumer_secret"]
    access_token        = config["access_token"]
    access_token_secret = config["access_token_secret"]
    user                = config["user"]
    count               = config["count"]
    consumer = OAuth::Consumer.new(consumer_key, consumer_secret, { site: "http://api.twitter.com" })
    access_token = OAuth::AccessToken.new(consumer, access_token, access_token_secret)
    response = access_token.get("https://api.twitter.com/1.1/statuses/user_timeline.json?screen_name=#{user}&exclude_replies=true&include_rts=false&trim_user=true")
    tweets = JSON.parse(response.body).slice(0, count).map!{ |t| expand_tweet(t) }.to_json
    File.open("data/tweets.json","w"){ |f| f << tweets }
  rescue => e
    puts e
  end
end

def get_twitter_user
  begin
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
    File.open("source/images/twitter/#{twitter_user["screen_name"]}.jpg","wb"){ |f| f << HTTParty.get(twitter_user["profile_image_url"].sub("_normal", "")).body }
  rescue => e
    puts e
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
  begin
    config = get_config["instagram"]
    user_id      = config["user_id"]
    consumer_key = config["consumer_key"]
    count        = config["count"]
    response = HTTParty.get("https://api.instagram.com/v1/users/#{user_id}/media/recent/?client_id=#{consumer_key}&count=#{count}")
    photos = JSON.parse(response.body)["data"]
    save_instagram_photos(photos) unless photos.nil?
    File.open("data/instagram.json","w"){ |f| f << photos.to_json }
  rescue => e
    puts e
  end
end

def save_instagram_photos(data)
  data.each do |photo|
    id = photo["id"]
    File.open("source/images/instagram/#{id}_640.jpg","wb"){ |f| f << HTTParty.get(photo["images"]["standard_resolution"]["url"]).body }
  end
end

def get_photoblog_photos
  begin
    config = get_config["tumblr"]
    url          = config["url"]
    consumer_key = config["consumer_key"]
    count        = config["count"]
    response = HTTParty.get("http://api.tumblr.com/v2/blog/#{url}/posts/photo?api_key=#{consumer_key}&limit=#{count}")
    data = JSON.parse(response.body)
    save_photoblog_photos(data) unless data.nil?
    File.open("data/photoblog.json","w"){ |f| f << data.to_json }
  rescue => e
    puts e
  end
end

def save_photoblog_photos(data)
  data["response"]["posts"].each do |post|
    post_id = post["id"]
    # Tumblr posts can have more than one photo (photosets),
    # but I'm only interested in showing the first one.
    url = post["photos"][0]["original_size"]["url"]
    File.open("source/images/photoblog/#{post_id}_original.jpg","wb"){ |f| f << HTTParty.get(url).body }
  end
end

def get_github_repos
  begin
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
    repo_array.sort!{ |a,b| b["watchers"] <=> a["watchers"] }
    File.open("data/repos.json","w"){ |f| f << repo_array.to_json }
  rescue => e
    puts e
  end
end

def get_lastfm_data
  begin
    config = get_config["lastfm"]
    api_key  = config["api_key"]
    username = config["username"]
    count    = config["count"]
    response = HTTParty.get("http://ws.audioscrobbler.com/2.0/?method=user.getweeklyartistchart&user=#{username}&api_key=#{api_key}&format=json")
    artists = JSON.parse(response.body)["weeklyartistchart"]["artist"].slice(0, count)
    File.open("data/lastfm.json","w"){ |f| f << artists.to_json }
  rescue => e
    puts e
  end
end

def get_goodreads_data
  begin
    config = get_config["goodreads"]
    shelves = config["shelves"]
    count   = config["count"]
    books = []
    shelves.each do |shelf|
      books << import_goodreads_shelf(shelf)
    end
    books = books.flatten.slice(0, count)
    books.each do |book|
      File.open("source/images/goodreads/#{book[:id]}.jpg","wb"){ |f| f << HTTParty.get(book[:image]).body }
    end
    File.open("data/goodreads.json","w"){ |f| f << books.to_json }
  rescue => e
    puts e
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
      url: item.xpath('link').first.content,
      shelf: shelf
    }
    books << book
  end
  books
end

def get_untappd_data
  begin
    beers = []
    config = get_config["untappd"]
    checkins_endpoint = config["checkins"]
    count             = config["count"]
    checkins = JSON.parse(HTTParty.get(checkins_endpoint).body)["results"]["beers"].slice(0, count)
    checkins.each do |c|
      beer_html = Nokogiri::HTML(HTTParty.get(c["name"]["href"]).body)
      beer = {
        checkin: c["checkin"],
        checkin_url: c["date"]["href"],
        date: c["date"]["data-gregtime"],
        name: c["name"]["text"],
        url: c["name"]["href"],
        brewery: c["brewery"]["text"],
        brewery_url: c["brewery"]["href"],
        type: beer_html.css("p.style").first.content.strip,
        abv: beer_html.css("p.abv").first.content.strip,
        ibu: beer_html.css("p.ibu").first.content.strip
      }
      beers << beer
      File.open("source/images/untappd/#{c["checkin"]}.jpg","wb"){ |f| f << HTTParty.get(c["image"]).body }
    end
    File.open("data/untappd.json","w"){ |f| f << beers.to_json }
  rescue => e
    puts e
  end
end