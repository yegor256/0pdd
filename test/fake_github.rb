# Copyright (c) 2016-2022 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

class FakeGithub
  attr_reader :name, :repo

  def initialize(options = {})
    @name = 'GITHUB'
    @memberships = options[:memberships] || [
      {
        'state' => 'pending',
        'organization' => {
          'login' => 'github'
        }
      }, {
        'state' => 'pending',
        'organization' => {
          'login' => 'zerocracy'
        }
      }
    ]
    @invitations = options[:invitations] || [
      {
        'id' => 1001,
        'repository' => {
          'name' => 'yegor256/0pdd'
        }
      }, {
        'id' => 1023,
        'repository' => {
          'name' => 'yegor256/sixnines'
        }
      }
    ]
    @repositories = options[:repositories] || []
    @repo = options[:repo]
  end

  def rate_limit
    limit = Object.new

    def limit.remaining
      4096
    end
    limit
  end

  def update_organization_membership(org, options = {})
    return unless options['state']
    @memberships.find do |m|
      m['organization']['login'] == org
    end['state'] = options['state']
  end

  def organization_memberships(options = {})
    if options['state']
      @memberships.find_all { |m| m['state'] == options['state'] }
    else
      @memberships
    end
  end

  def user_repository_invitations(_options = {})
    @invitations
  end

  def accept_repository_invitation(id, _options = {})
    invitation = @invitations.find { |i| i['id'] == id }
    return false if invitation.nil?
    @repositories.push(invitation['repository']['name'])
    true
  end

  def repositories(user = nil, _options = {})
    return @repositories unless user
  end

  def issue(_)
    {
      state: 'open',
      author: {
        id: '1',
        username: 'yegor256'
      },
      milestone: {
        number: 1,
        title: 'v0.1'
      }
    }
  end

  def close_issue(_); end

  def create_issue(_)
    {
      number: 1,
      html_url: 'url'
    }
  end

  def update_issue(_, _); end

  def labels
    [
      {
        id: ``,
        name: 'Dev',
        color: '#ff00ff'
      }
    ]
  end

  def add_label(_, _); end

  def add_labels_to_an_issue(_, _); end

  def add_comment(_, _); end

  def create_commit_comment(_, _, _)
    {
      html_url: 'url'
    }
  end

  def list_commits
    [
      {
        sha: '123456',
        html_url: 'url'
      }
    ]
  end

  def user(_)
    {
      name: 'foobar',
      email: 'foobar@example.com'
    }
  end

  def star; end

  def repository(_ = nil)
    {
      private: false
    }
  rescue Octokit::NotFound => e
    raise "Repository #{name} is not available: #{e.message}"
  end

  def repository_link
    "https://github.com/#{@repo.name}"
  end

  def collaborators_link
    "https://github.com/#{@repo.name}/settings/collaboration"
  end

  def file_link(file)
    "https://github.com/#{@repo.name}/blob/#{@repo.master}/#{file})"
  end

  def puzzle_link_for_commit(sha, file, start, stop)
    "https://github.com/#{@repo.name}/blob/#{sha}/#{file}#L#{start}-L#{stop}"
  end

  def issue_link(issue_id)
    "https://github.com/#{@repo.name}/issues/#{issue_id}"
  end

  private

  def git_repo
    # Output:
    # repo -> GitRepo
    raise NotImplementedError, 'You must implement this method'
  end
end
