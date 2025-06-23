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

class FakeJira
  attr_reader :name, :repo

  def initialize(options = {})
    @name = 'JIRA'
    @repositories = options[:repositories] || []
    @repo = options[:repo]
  end

  def repositories(user = nil, _options = {})
    @repositories unless user
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

  def create_commit_comment(_, _)
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
      name: 'yegor256',
      email: 'yegor256@example.com'
    }
  end

  def star; end

  def repository(_ = nil)
    {
      private: false
    }
  rescue JIRA::Error::NotFound => e
    raise "Repository #{name} is not available: #{e.message}"
  end

  private

  def git_repo
    # Output:
    # repo -> GitRepo
    raise NotImplementedError, 'You must implement this method'
  end
end
