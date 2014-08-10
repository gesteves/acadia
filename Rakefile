require "rake/clean"
require "./import"

CLOBBER.include("data/*", "source/images/instagram/*", "source/images/tumblr/*")

namespace :import do
  directory "data"
  directory "source/images/instagram"
  directory "source/images/tumblr"
  task :set_up_directories => ["data", "source/images/instagram", "source/images/tumblr"]

  desc "Import latest tweets from a twitter account"
  task :twitter => [:set_up_directories] do
    puts "Importing tweets"
    start_time = Time.now
    get_tweets
    puts "Completed in #{Time.now - start_time} seconds"
  end

  desc "Import latest photos from Instagram"
  task :instagram => [:set_up_directories] do
    puts "Importing Instagram photos"
    start_time = Time.now
    get_instagram_photos
    puts "Completed in #{Time.now - start_time} seconds"
  end

  desc "Import latest photos from Tumblr"
  task :tumblr => [:set_up_directories] do
    puts "Importing latest photos from Tumblr"
    start_time = Time.now
    get_tumblr_photos
    puts "Completed in #{Time.now - start_time} seconds"
  end
end

task :import => ["clobber", "import:twitter", "import:instagram", "import:tumblr"]