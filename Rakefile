require "rake/clean"
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

  desc "Import latest links from Tumblr"
  task :links => [:set_up_directories] do
    puts "== Importing links"
    start_time = Time.now
    get_tumblr_links
    puts "Completed in #{Time.now - start_time} seconds"
  end

  desc "Import featured repos from Github"
  task :github => [:set_up_directories] do
    puts "== Importing Github repos"
    start_time = Time.now
    get_github_repos
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

  desc "Import data from Rdio"
  task :rdio => [:set_up_directories] do
    puts "== Importing data from Rdio"
    start_time = Time.now
    get_rdio_data
    puts "Completed in #{Time.now - start_time} seconds"
  end
end

task :import => [ "clobber",
                  "import:twitter",
                  "import:instagram",
                  "import:photoblog",
                  "import:links",
                  "import:github",
                  "import:goodreads",
                  "import:untappd",
                  "import:rdio" ]

namespace :publish do
  desc "Import content and publish the site"
  task :full => [:import] do
    puts "== Building the site"
    system("middleman build")
    puts "== Syncing with S3"
    system("middleman s3_sync")
  end

  desc "Just publish the site"
  task :simple do
    puts "== Building the site"
    system("middleman build")
    puts "== Syncing with S3"
    system("middleman s3_sync")
  end
end