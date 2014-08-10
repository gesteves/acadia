require "oauth"
require "httparty"

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
    response = access_token.get("https://api.twitter.com/1.1/statuses/user_timeline.json?screen_name=#{user}&exclude_replies=true&include_rts=false")
    tweets = JSON.parse(response.body).slice(0, count).to_json
    File.open("data/twitter.json","w"){ |f| f << tweets }
  rescue OAuth::Error => e
    puts e
  end
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
  rescue HTTParty::Error => e
    puts e
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

def get_tumblr_photos
  begin
    config = get_config["tumblr"]
    url          = config["url"]
    consumer_key = config["consumer_key"]
    count        = config["count"]
    response = HTTParty.get("http://api.tumblr.com/v2/blog/#{url}/posts/photo?api_key=#{consumer_key}&limit=#{count}&filter=text")
    data = JSON.parse(response.body)
    save_tumblr_photos(data) unless data.nil?
    File.open("data/tumblr.json","w"){ |f| f << data.to_json }
  rescue HTTParty::Error => e
    puts e
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
    File.open("data/repos.json","w"){ |f| f << repo_array.to_json }
  rescue HTTParty::Error => e
    puts e
  end
end