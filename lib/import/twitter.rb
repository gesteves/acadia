require 'oauth'
require 'httparty'
require 'RMagick'

module Import
  class Twitter

    def initialize(consumer_key, consumer_secret, access_token, access_token_secret, user, tweet_count = 1, exclude_replies = true)
      @user            = user
      @tweet_count     = tweet_count
      @exclude_replies = exclude_replies
      consumer = OAuth::Consumer.new(consumer_key, consumer_secret, { :site => 'http://api.twitter.com' })
      @access_token = OAuth::AccessToken.new(consumer, access_token, access_token_secret)
    end

    def get_tweets
      response = @access_token.get("https://api.twitter.com/1.1/statuses/user_timeline.json?screen_name=#{@user}&exclude_replies=#{@exclude_replies}&include_rts=false&trim_user=true&count=200")
      tweets = JSON.parse(response.body).slice(0, @tweet_count).map!{ |t| Twitter.expand_tweet(t) }.to_json
      File.open('data/tweets.json','w'){ |f| f << tweets }
    end

    def get_twitter_user
      response = @access_token.get("https://api.twitter.com/1.1/users/show.json?screen_name=#{@user}")
      twitter_user = JSON.parse(response.body)
      File.open('data/twitter.json','w'){ |f| f << response.body }
      avatar = Magick::Image::from_blob(HTTParty.get(twitter_user['profile_image_url'].sub('_normal', '')).body).first
      sizes = [200, 150, 100, 50]
      sizes.each do |size|
        image = avatar.resize_to_fill(size, (size * avatar.rows)/avatar.columns)
        image.write("source/images/twitter/#{twitter_user["screen_name"]}_#{size}.jpg"){ self.interlace = Magick::LineInterlace }
      end
    end

    # Horrible method to expand tweet entities (urls, hashtags, mentions, etc.) in tweets
    def self.expand_tweet(tweet)
      text = tweet['text']
      # Put all the entities into an array and sort them by starting index
      entities = []
      entities += tweet['entities']['urls'] unless tweet['entities']['urls'].nil?
      entities += tweet['entities']['user_mentions'] unless tweet['entities']['user_mentions'].nil?
      entities += tweet['entities']['media'] unless tweet['entities']['media'].nil?
      entities += tweet['entities']['hashtags'] unless tweet['entities']['hashtags'].nil?
      entities.sort!{ |a,b| a['indices'].first <=> b['indices'].first } if entities.size > 1
      if entities.empty?
        tweet['expanded_text'] = text
      else
        expanded_text = []
        entities.each_with_index do |e, i|
          # If it's the first entity, start by putting the text from the beginning of the tweet
          # to the start of the entity in the placeholder array
          if i == 0 && e['indices'].first > 0
            end_index = e['indices'].first - 1
            expanded_text << text[0..end_index]
          end

          # Now expand the entity link and place it in the array
          expanded_text << Twitter.expand_tweet_entity(e)

          # If I'm at the last entity, place the rest of the tweet text in the placeholder array
          if i == entities.size - 1
            start_index = e['indices'].last
            end_index = text.size - 1
            expanded_text << text[start_index..end_index]
          # If not, place the text between the end of the current entity and the start of the next one
          else
            start_index = e['indices'].last
            end_index = entities[i + 1]['indices'].first - 1
            expanded_text << text[start_index..end_index]
          end
        end

        # Now join the placeholder array into a string and put it in the tweet object
        tweet['expanded_text'] = expanded_text.join
      end
      # Return the tweet with the new expanded text. Phew.
      tweet
    end

    # Spit out the correct link tag for each type of entity
    def self.expand_tweet_entity(e)
      if !e['display_url'].nil? && !e['url'].nil?
        Twitter.link_to(e['display_url'], e['url'])
      elsif !e['screen_name'].nil?
        Twitter.link_to("@#{e["screen_name"]}", "https://twitter.com/#{e["screen_name"]}")
      elsif !e["text"].nil?
        Twitter.link_to("##{e["text"]}", "https://twitter.com/hashtag/#{e["text"]}")
      end
    end

    def self.link_to(text, url)
      "<a href=\"#{url}\">#{text}</a>"
    end
  end
end
