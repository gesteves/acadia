require "dotenv/tasks"
require "rake/clean"
require "./import"

CLOBBER.include("data/*", "source/images/instagram/*", "source/images/tumblr/*")

namespace :import do
  directory "data"
  directory "source/images/instagram"
  directory "source/images/tumblr"
  task :set_up_directories => ["data", "source/images/instagram", "source/images/tumblr"]

  desc "Import latest tweets from a twitter account"
  task :twitter => [:set_up_directories, :dotenv] do
    twitter = ENV["TWITTER_USER"]
    puts "Importing latest tweets from @#{twitter}"
    start_time = Time.now
    get_tweets(twitter, 5)
    puts "Completed in #{Time.now - start_time} seconds"
  end

  desc "Import latest photos from Instagram"
  task :instagram => [:set_up_directories, :dotenv] do
    user_id = ENV["INSTAGRAM_USER_ID"]
    client_id = ENV["INSTAGRAM_CONSUMER_KEY"]
    puts "Importing latest Instagram photos from user #{user_id}"
    start_time = Time.now
    get_instagram_photos(user_id, client_id, 9)
    puts "Completed in #{Time.now - start_time} seconds"
  end

  desc "Import latest photos from Tumblr"
  task :tumblr => [:set_up_directories, :dotenv] do
    tumblr_key = ENV["TUMBLR_CONSUMER_KEY"]
    tumblr_url = ENV["TUMBLR_URL"]
    puts "Importing latest photos from user #{tumblr_url}"
    start_time = Time.now
    get_tumblr_photos(tumblr_url, tumblr_key, 1)
    puts "Completed in #{Time.now - start_time} seconds"
  end
end

task :import => ["clobber", "import:twitter", "import:instagram", "import:tumblr"]