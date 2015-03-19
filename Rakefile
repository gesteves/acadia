require 'rake/clean'
require 'dotenv/tasks'
require 'open-uri'
require 'cloudfront-invalidator'
require_relative 'lib/import'

CLOBBER.include('data/*.json', 'source/images/instagram/*', 'source/images/photoblog/*', 'source/images/goodreads/*', 'source/images/untappd/*', 'source/images/twitter/*', 'source/images/rdio/*')

namespace :import do
  directory 'data'
  directory 'source/images/instagram'
  directory 'source/images/photoblog'
  directory 'source/images/goodreads'
  directory 'source/images/untappd'
  directory 'source/images/twitter'
  directory 'source/images/rdio'
  
  task :set_up_directories => ['data', 'source/images/goodreads', 'source/images/instagram', 'source/images/photoblog', 'source/images/untappd', 'source/images/twitter', 'source/images/rdio']

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
      instagram = Import::Instagram.new(ENV['INSTAGRAM_USER_ID'], ENV['INSTAGRAM_CONSUMER_KEY'], ENV['INSTAGRAM_COUNT'].to_i)
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
      photoblog = Import::Photoblog.new(ENV['TUMBLR_CONSUMER_KEY'], ENV['TUMBLR_PHOTOBLOG'], ENV['TUMBLR_PHOTO_TAG'], ENV['TUMBLR_PHOTOS_COUNT'].to_i)
      photoblog.get_photos
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to import photoblog photos: #{e}"
    end
  end

  desc 'Import latest links from Tumblr'
  task :links => [:dotenv, :set_up_directories] do
    begin
      puts '== Importing links'
      start_time = Time.now
      linkblog = Import::LinkBlog.new(ENV['TUMBLR_CONSUMER_KEY'], ENV['TUMBLR_LINKS'],ENV['TUMBLR_LINK_TAG'], ENV['TUMBLR_LINKS_COUNT'].to_i)
      linkblog.get_links
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to import links: #{e}"
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

  desc 'Import data from Rdio'
  task :rdio => [:dotenv, :set_up_directories] do
    begin
      puts '== Importing data from Rdio'
      start_time = Time.now
      rdio = Import::Rdio.new(ENV['RDIO_USER_ID'], ENV['RDIO_KEY'], ENV['RDIO_SECRET'], ENV['RDIO_COUNT'].to_i)
      rdio.get_heavy_rotation
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to import Rdio data: #{e}"
    end
  end

  desc 'Import activity from Fitbit'
  task :fitbit => [:dotenv, :set_up_directories] do
    begin
      puts '== Importing Fitbit data'
      start_time = Time.now
      fitbit = Import::Fitbit.new(ENV['FITBIT_CONSUMER_KEY'], ENV['FITBIT_CONSUMER_SECRET'], ENV['FITBIT_ACCESS_TOKEN'], ENV['FITBIT_ACCESS_TOKEN_SECRET'])
      fitbit.get_steps
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to import Fitbit data: #{e}"
    end
  end

  desc 'Import score from WPT'
  task :wpt => [:dotenv, :set_up_directories] do
    begin
      puts '== Importing WPT test results'
      start_time = Time.now
      wpt = Import::WPT.new(ENV['SITE_URL'], ENV['WPT_API_KEY'])
      wpt.results
      puts "Completed in #{Time.now - start_time} seconds"
    rescue => e
      abort "Failed to import WPT results: #{e}"
    end
  end
end

task :import => [ 'clobber',
                  'import:twitter',
                  'import:instagram',
                  'import:photoblog',
                  'import:links',
                  'import:github',
                  'import:goodreads',
                  'import:untappd',
                  'import:rdio',
                  'import:fitbit',
                  'import:wpt' ]

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

desc 'Requests a new WebPageTest test'
task :wpt => [:dotenv] do
  begin
    puts '== Requesting new WPT test'
    start_time = Time.now
    open(ENV['SITE_URL']) unless ENV['SITE_URL'].nil?
    wpt = Import::WPT.new(ENV['SITE_URL'], ENV['WPT_API_KEY'])
    wpt.request_test
    puts "Completed in #{Time.now - start_time} seconds"
  rescue => e
    abort "Failed to request WPT test: #{e}"
  end
end

desc 'Publishes the site'
task :publish => [:dotenv, :build, :sync] do
  open("https://nosnch.in/#{ENV['SNITCH_ID']}") unless ENV['SNITCH_ID'].nil?
end

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
