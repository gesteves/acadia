require 'httparty'

module Import
  class Github
    def initialize(access_token, repos, stat_days)
      @access_token = access_token
      @repos = repos
      @stat_days = stat_days
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

    def get_stats
      commits = {
        :total_commits => 0,
        :additions => 0,
        :deletions => 0
      }
      pushes = get_push_events(Time.now - (@stat_days * 60 * 60 * 24))
      pushes.each do |p|
        p['payload']['commits'].find_all{ |c| c['distinct'] }.each do |c|
          stats = get_commit_stats(c['url'])
          unless stats.nil?
            commits[:total_commits] += 1
            commits[:additions] += stats['additions']
            commits[:deletions] += stats['deletions']
          end
        end
      end
      File.open('data/commits.json','w'){ |f| f << commits.to_json }
    end

    def get_push_events(oldest, page = 1)
      events = JSON.parse(HTTParty.get("https://api.github.com/users/gesteves/events?access_token=#{@access_token}&page=#{page}",
                          :headers => { 'User-Agent' => 'gesteves/acadia' }).body)
      pushes = events.find_all{ |e| e['type'] == 'PushEvent' && Time.parse(e['created_at']) >= oldest }
      if page < 10 && (pushes.nil? || pushes.size == 0 || Time.parse(pushes.last['created_at']) > oldest)
        pushes += get_push_events(oldest, page + 1)
      end
      pushes
    end

    def get_commit_stats(url)
      commit = JSON.parse(HTTParty.get("#{url}?access_token=#{@access_token}",
                          :headers => { 'User-Agent' => 'gesteves/acadia' }).body)
      commit['stats']
    end
  end
end
