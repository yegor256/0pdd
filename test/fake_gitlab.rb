# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

class FakeGitlab
  attr_reader :name, :repo

  def initialize(options = {})
    @name = 'GITLAB'
    @repositories = options[:repositories] || []
    @projects = options[:projects] || []
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
      name: 'foobar',
      email: 'foobar@example.com'
    }
  end

  def star; end

  def repository(_ = nil)
    {
      private: false
    }
  end

  def project(_ = nil)
    {
      private: false
    }
  end

  def repository_link
    "https://gitlab.com/#{@repo.name}"
  end

  def collaborators_link
    "https://gitlab.com/#{@repo.name}/project_members"
  end

  def file_link(file)
    "https://gitlab.com/#{@repo.name}/blob/#{@repo.master}/#{file})"
  end

  def puzzle_link_for_commit(sha, file, start, stop)
    "https://gitlab.com/#{@repo.name}/blob/#{sha}/#{file}#L#{start}-L#{stop}"
  end

  def issue_link(issue_id)
    "https://gitlab.com/#{@repo.name}/issues/#{issue_id}"
  end

  private

  def git_repo
    # Output:
    # repo -> GitRepo
    raise NotImplementedError, 'You must implement this method'
  end
end
