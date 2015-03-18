require 'httparty'

module Import
  class WPT
    def initialize(url)
      @url = url
    end

    def results
      result = HTTParty.get(@url).body
      File.open('data/wpt.json','w'){ |f| f << result }
    end
  end
end
