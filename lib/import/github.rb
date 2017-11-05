require 'httparty'

module Import
  class Github
    def initialize(access_token, repos)
      @access_token = access_token
      @repos = repos
    end

    def get_repos
      repo_array = []
      @repos.each do |r|
        owner = r.split('/').first
        name = r.split('/').last
        response = HTTParty.get("https://api.github.com/repos/#{owner}/#{name}?access_token=#{@access_token}",
                                :headers => { 'User-Agent' => 'gesteves/acadia' })
        repo_array << JSON.parse(response.body)
      end
      repo_array.sort!{ |a,b| a['name'] <=> b['name'] }
      File.open('data/repos.json','w'){ |f| f << repo_array.to_json }
    end
  end
end
