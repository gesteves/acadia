require 'rake/clean'
require 'dotenv/tasks'
require 'open-uri'
require 'cloudfront-invalidator'
require_relative 'lib/import'

CLOBBER.include('data/*.json', 'source/images/instagram/*', 'source/images/photoblog/*', 'source/images/goodreads/*', 'source/images/untappd/*', 'source/images/twitter/*', 'source/images/music/*')

namespace :import do
  directory 'data'
  directory 'source/images/instagram'
  directory 'source/images/photoblog'
  directory 'source/images/goodreads'
  directory 'source/images/untappd'
  directory 'source/images/twitter'
  directory 'source/images/music'

  task :set_up_directories => ['data', 'source/images/instagram', 'source/images/photoblog', 'source/images/goodreads', 'source/images/untappd', 'source/images/twitter', 'source/images/music']

  desc 'Import latest tweets from a twitter account'
  task :twitter => [:dotenv, :set_up_directories] do
    begin
      puts '== Importing tweets'
      start_time = Time.now
      twitter = Import::Twitter.new(ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET'], ENV['TWITTER_ACCESS_TOKEN'], ENV['TWITTER_ACCESS_TOKEN_SECRET'], ENV['TWITTER_USER'], ENV['TWITTER_COUNT'].to_i, ENV['TWITTER_EXCLUDE_REPLIES'])
      twitter.get_tweets
      twitter.get_twitter_user
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to import tweets: #{e}"
    end
  end

  desc 'Import latest photos from Instagram'
  task :instagram => [:dotenv, :set_up_directories] do
    begin
      puts '== Importing Instagram photos'
      start_time = Time.now
      instagram = Import::Instagram.new(ENV['INSTAGRAM_USER_ID'], ENV['INSTAGRAM_ACCESS_TOKEN'], ENV['INSTAGRAM_COUNT'].to_i)
      instagram.get_photos
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to import Instagram photos: #{e}"
    end
  end

  desc 'Import latest photoblog photos from Tumblr'
  task :photoblog => [:dotenv, :set_up_directories] do
    begin
      puts '== Importing photoblog photos'
      start_time = Time.now
      photoblog = Import::Photoblog.new(ENV['PHOTOBLOG_URL'], ENV['PHOTOBLOG_TAG'])
      photoblog.get_photos
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to import photoblog photos: #{e}"
    end
  end

  desc 'Import featured repos from Github'
  task :github => [:dotenv, :set_up_directories] do
    begin
      puts '== Importing Github data'
      start_time = Time.now
      repos = YAML.load_file('data/content.yml')['repos']
      github = Import::Github.new(ENV['GITHUB_ACCESS_TOKEN'], repos, ENV['GITHUB_STATS_DAYS'].to_i)
      github.get_repos
      github.get_stats
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
     abort "Failed to import Github data: #{e}"
    end
  end

  desc 'Import data from Goodreads'
  task :goodreads => [:dotenv, :set_up_directories] do
    begin
      puts '== Importing data from Goodreads'
      start_time = Time.now
      goodreads = Import::Goodreads.new(ENV['GOODREADS_RSS_FEED'], ENV['GOODREADS_COUNT'].to_i)
      goodreads.get_books
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to import Goodreads data: #{e}"
    end
  end

  desc 'Import data from Untappd'
  task :untappd => [:dotenv, :set_up_directories] do
    begin
      puts '== Importing data from Untappd'
      start_time = Time.now
      untappd = Import::Untappd.new(ENV['UNTAPPD_USERNAME'], ENV['UNTAPPD_CLIENT_ID'], ENV['UNTAPPD_CLIENT_SECRET'], ENV['UNTAPPD_COUNT'].to_i)
      untappd.get_beers
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to import Untappd data: #{e}"
    end
  end

  desc 'Import data from Spotify'
  task :music => [:dotenv, :set_up_directories] do
    begin
      puts '== Importing Spotify data'
      start_time = Time.now
      music = Import::Music.new(ENV['SPOTIFY_REFRESH_TOKEN'])
      music.spotify
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to import Music data: #{e}"
    end
  end

  desc 'Import score from WPT'
  task :wpt => [:dotenv, :set_up_directories] do
    begin
      puts '== Importing WPT test results'
      start_time = Time.now
      wpt = Import::WPT.new(ENV['SITE_URL'], ENV['WPT_API_KEY'])
      wpt.save_results
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to import WPT results: #{e}"
    end
  end
end

namespace :wpt do
  desc 'Requests a new WebPageTest test'
  task :request => [:dotenv] do
    begin
      puts '== Requesting new WPT test'
      start_time = Time.now
      wpt = Import::WPT.new(ENV['SITE_URL'], ENV['WPT_API_KEY'])
      wpt.request_test
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to request WPT test: #{e}"
    end
  end
end

task :import => %w{
  clobber
  import:wpt
  import:twitter
  import:instagram
  import:photoblog
  import:github
  import:goodreads
  import:untappd
  import:music
}

desc 'Import content and build the site'
task :build => [:dotenv, :import] do
  puts '== Building the site'
  system('middleman build')
end

desc 'Sync the site to S3'
task :sync do
  puts '== Syncing with S3'
  system('middleman s3_sync')
end

desc 'Publishes the site'
task :publish => [:dotenv, :build, :sync]

desc 'Send CloudFront invalidation request'
task :invalidate => [:dotenv] do
  unless ENV['AWS_CLOUDFRONT_DISTRIBUTION_ID'].nil?
    puts '== Sending CloudFront invalidation request'
    start_time = Time.now
    invalidator = CloudfrontInvalidator.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY_ID'], ENV['AWS_CLOUDFRONT_DISTRIBUTION_ID'])
    list = %w{
      index.html
    }
    invalidator.invalidate(list)
    puts "Completed in #{Time.now - start_time} seconds"
  end
end
