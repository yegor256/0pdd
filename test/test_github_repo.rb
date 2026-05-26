# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative '../objects/vcs/github'

# GithubRepo test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2026 Yegor Bugayenko
# License:: MIT
class TestGithubRepo < Minitest::Test
  def test_tracks_close_failures
    client = Object.new
    response = error_response
    client.define_singleton_method(:close_issue) do |_, _|
      raise Octokit::Error, response
    end
    refute(repo(client).close_issue(1))
  end

  def test_tracks_comment_failures
    client = Object.new
    response = error_response
    client.define_singleton_method(:add_comment) do |_, _, _|
      raise Octokit::Error, response
    end
    refute(repo(client).add_comment(1, 'hello'))
  end

  private

  def repo(client)
    GithubRepo.new(
      client,
      {
        'repository' => {
          'ssh_url' => 'git@github.com:yegor256/0pdd.git',
          'url' => 'https://github.com/yegor256/0pdd',
          'full_name' => 'yegor256/0pdd',
          'master_branch' => 'master'
        },
        'ref' => 'refs/heads/master',
        'head_commit' => {
          'id' => 'abc'
        }
      },
      {}
    )
  end

  def error_response
    {
      method: :patch,
      url: 'https://api.github.test/repos/yegor256/0pdd/issues/1',
      status: 500,
      body: 'boom',
      response_headers: {}
    }
  end
end
