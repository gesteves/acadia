require "rake/clean"
require "dotenv/tasks"
require "./import"

CLOBBER.include("data/*.json", "source/images/instagram/*", "source/images/photoblog/*", "source/images/goodreads/*", "source/images/untappd/*", "source/images/twitter/*", "source/images/rdio/*")

namespace :import do
  directory "data"
  directory "source/images/instagram"
  directory "source/images/photoblog"
  directory "source/images/goodreads"
  directory "source/images/untappd"
  directory "source/images/twitter"
  directory "source/images/rdio"
  
  task :set_up_directories => ["data", "source/images/goodreads", "source/images/instagram", "source/images/photoblog", "source/images/untappd", "source/images/twitter", "source/images/rdio"]

  desc "Import latest tweets from a twitter account"
  task :twitter => [:set_up_directories] do
    begin
      puts "== Importing tweets"
      start_time = Time.now
      get_tweets
      get_twitter_user
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to import tweets: #{e}"
    end
  end

  desc "Import latest photos from Instagram"
  task :instagram => [:set_up_directories] do
    begin
      puts "== Importing Instagram photos"
      start_time = Time.now
      get_instagram_photos
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to import Instagram photos: #{e}"
    end
  end

  desc "Import latest photoblog photos from Tumblr"
  task :photoblog => [:set_up_directories] do
    begin
      puts "== Importing photoblog photos"
      start_time = Time.now
      get_photoblog_photos
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to import photoblog photos: #{e}"
    end
  end

  desc "Import latest links from Tumblr"
  task :links => [:set_up_directories] do
    begin
      puts "== Importing links"
      start_time = Time.now
      get_tumblr_links
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to import links: #{e}"
    end
  end

  desc "Import featured repos from Github"
  task :github => [:set_up_directories] do
    begin
    puts "== Importing Github repos"
      start_time = Time.now
      get_github_repos
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to import repos: #{e}"
    end
  end

  desc "Import data from Goodreads"
  task :goodreads => [:set_up_directories] do
    begin
      puts "== Importing data from Goodreads"
      start_time = Time.now
      get_goodreads_data
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to import Goodreads data: #{e}"
    end
  end

  desc "Import data from Untappd"
  task :untappd => [:set_up_directories] do
    begin
      puts "== Importing data from Untappd"
      start_time = Time.now
      get_untappd_data
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to import Untappd data: #{e}"
    end
  end

  desc "Import data from Rdio"
  task :rdio => [:set_up_directories] do
    begin
      puts "== Importing data from Rdio"
      start_time = Time.now
      get_rdio_data
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to import Rdio data: #{e}"
    end
  end

  desc "Import activity from Fitbit"
  task :fitbit => [:set_up_directories] do
    begin
      puts "== Importing Fitbit data"
      start_time = Time.now
      get_fitbit_data
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to import Fitbit: #{e}"
    end
  end
end

task :import => [ "dotenv",
                  "clobber",
                  "import:twitter",
                  "import:instagram",
                  "import:photoblog",
                  "import:links",
                  "import:github",
                  "import:goodreads",
                  "import:untappd",
                  "import:rdio",
                  "import:fitbit" ]

desc "Import content and publish the site"
task :publish => [:import] do
  puts "== Building the site"
  system("middleman build")
  puts "== Syncing with S3"
  system("middleman s3_sync")
end