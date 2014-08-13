require "rake/clean"
require "./import"

CLOBBER.include("data/*.json", "source/images/instagram/*", "source/images/photoblog/*", "source/images/goodreads/*", "source/images/untappd/*")

namespace :import do
  directory "data"
  directory "source/images/instagram"
  directory "source/images/photoblog"
  directory "source/images/goodreads"
  directory "source/images/untappd"
  task :set_up_directories => ["data", "source/images/goodreads", "source/images/instagram", "source/images/photoblog", "source/images/untappd"]

  desc "Import latest tweets from a twitter account"
  task :twitter => [:set_up_directories] do
    puts "== Importing tweets"
    start_time = Time.now
    get_tweets
    get_twitter_user
    puts "Completed in #{Time.now - start_time} seconds"
  end

  desc "Import latest photos from Instagram"
  task :instagram => [:set_up_directories] do
    puts "== Importing Instagram photos"
    start_time = Time.now
    get_instagram_photos
    puts "Completed in #{Time.now - start_time} seconds"
  end

  desc "Import latest photoblog photos from Tumblr"
  task :photoblog => [:set_up_directories] do
    puts "== Importing photoblog photos"
    start_time = Time.now
    get_photoblog_photos
    puts "Completed in #{Time.now - start_time} seconds"
  end

  desc "Import featured repos from Github"
  task :github => [:set_up_directories] do
    puts "== Importing Github repos"
    start_time = Time.now
    get_github_repos
    puts "Completed in #{Time.now - start_time} seconds"
  end

  desc "Import data from Last.fm"
  task :lastfm => [:set_up_directories] do
    puts "== Importing data from Last.fm"
    start_time = Time.now
    get_lastfm_data
    puts "Completed in #{Time.now - start_time} seconds"
  end

  desc "Import data from Goodreads"
  task :goodreads => [:set_up_directories] do
    puts "== Importing data from Goodreads"
    start_time = Time.now
    get_goodreads_data
    puts "Completed in #{Time.now - start_time} seconds"
  end

  desc "Import data from Untappd"
  task :untappd => [:set_up_directories] do
    puts "== Importing data from Untappd"
    start_time = Time.now
    get_untappd_data
    puts "Completed in #{Time.now - start_time} seconds"
  end
end

task :import => [ "clobber",
                  "import:twitter",
                  "import:instagram",
                  "import:photoblog",
                  "import:github",
                  "import:lastfm",
                  "import:goodreads",
                  "import:untappd" ]

desc "Import data and build the website"
task :build => ["import"] do
  puts "== Building website"
  start_time = Time.now
  status = system("middleman build --clean")
  puts status ? "OK" : "FAILED"
  puts "Completed in #{Time.now - start_time} seconds"
end
 
desc "Run the preview server at http://localhost:4567"
task :preview => [:import] do
  puts "== Starting Middleman"
  system("middleman server")
end