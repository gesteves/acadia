require 'rdioid'

module Import
  class Rdio
    def initialize(user_id, consumer_key, consumer_secret, refresh_token, count)
      Rdioid.configure do |config|
        config.client_id = consumer_key
        config.client_secret = consumer_secret
      end
      @user_id = user_id
      @count = count
      @rdio_client = Rdioid::Client.new
      @access_token = @rdio_client.request_token_with_refresh_token(refresh_token)['access_token']
    end

    def get_heavy_rotation
      params = { :method => 'getHeavyRotation', :user => @user_id, :type => 'albums', :friends => false, :count => @count }
      response = @rdio_client.api_request(@access_token, params)
      albums = response['result']
      File.open('data/rdio.json','w'){ |f| f << albums.to_json }
    end
  end
end
