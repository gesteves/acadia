require "oauth"
require "httparty"

def get_tweets(username, count = 5)
  begin
    consumer = OAuth::Consumer.new(ENV["TWITTER_CONSUMER_KEY"], ENV["TWITTER_CONSUMER_SECRET"], { site: "http://api.twitter.com" })
    access_token = OAuth::AccessToken.new(consumer, ENV["TWITTER_ACCESS_TOKEN"], ENV["TWITTER_ACCESS_TOKEN_SECRET"])
    response = access_token.get("https://api.twitter.com/1.1/statuses/user_timeline.json?screen_name=#{username}&exclude_replies=true&include_rts=false")
    tweets = JSON.parse(response.body).slice(0, count).to_json
    File.open("data/twitter.json","w"){ |f| f << tweets } unless tweets.nil?
  rescue OAuth::Error
    nil
  end
end

def get_instagram_photos(account_id, client_id, count = 10)
  begin
    response = HTTParty.get("https://api.instagram.com/v1/users/#{account_id}/media/recent/?client_id=#{client_id}&count=#{count}")
    photos = JSON.parse(response.body)["data"]
    save_instagram_photos(photos) unless photos.nil?
    File.open("data/instagram.json","w"){ |f| f << photos.to_json } unless photos.nil?
  rescue HTTParty::Error
    nil
  end
end

def save_instagram_photos(data)
  data.each do |photo|
    id = photo["id"]
    File.open("source/images/instagram/#{id}_150.jpg","wb"){ |f| f << HTTParty.get(photo["images"]["thumbnail"]["url"]).body }
    File.open("source/images/instagram/#{id}_306.jpg","wb"){ |f| f << HTTParty.get(photo["images"]["low_resolution"]["url"]).body }
    File.open("source/images/instagram/#{id}_640.jpg","wb"){ |f| f << HTTParty.get(photo["images"]["standard_resolution"]["url"]).body }
  end
end

def get_tumblr_photos(url, key, count = 1)
  begin
    response = HTTParty.get("http://api.tumblr.com/v2/blog/#{url}/posts/photo?api_key=#{key}&limit=#{count}&filter=text")
    data = JSON.parse(response.body)
    save_tumblr_photos(data) unless data.nil?
    File.open("data/tumblr.json","w"){ |f| f << data.to_json } unless data.nil?
  rescue HTTParty::Error
    nil
  end
end

def save_tumblr_photos(data)
  data["response"]["posts"].each do |post|
    post_id = post["id"]
    # Tumblr posts can have more than one photo (photosets),
    # but I'm only interested in showing the first one.
    post["photos"][0]["alt_sizes"].each do |size|
      width = size["width"]
      url = size["url"]
      File.open("source/images/tumblr/#{post_id}_#{width}.jpg","wb"){ |f| f << HTTParty.get(url).body }
    end
  end
end