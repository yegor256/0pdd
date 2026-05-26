# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative '../objects/clients/gitlab'
require_relative '../objects/vcs/gitlab'

# Github test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2026 Yegor Bugayenko
# License:: MIT
class TestGitlab < Minitest::Test
  def test_configures_everything_right
    gitlab = GitlabClient.new.client
    assert_raises Gitlab::Error::MissingCredentials do
      gitlab.user('0pdd')['username']
    end
  end

  def test_wraps_issue_read_errors
    error = assert_raises(RuntimeError) do
      gitlab_repo(client_raising(:issue, Gitlab::Error::Forbidden)).issue(42)
    end
    assert_includes(error.message, "Can't read GitLab issue 42:")
    assert_includes(error.message, 'denied')
  end

  def test_wraps_issue_close_errors
    error = assert_raises(RuntimeError) do
      gitlab_repo(client_raising(:close_issue, Gitlab::Error::TooManyRequests)).close_issue(42)
    end
    assert_includes(error.message, "Can't close GitLab issue 42:")
    assert_includes(error.message, 'denied')
  end

  def test_wraps_comment_errors
    error = assert_raises(RuntimeError) do
      gitlab_repo(client_raising(:create_issue_note, Net::OpenTimeout)).add_comment(42, 'hello')
    end
    assert_equal("Can't comment GitLab issue 42: denied", error.message)
  end

  private

  def gitlab_repo(client)
    GitlabRepo.new(
      client,
      {
        'ref' => 'refs/heads/master',
        'checkout_sha' => 'abcdef',
        'project' => {
          'url' => 'git@gitlab.com:yegor/0pdd.git',
          'path_with_namespace' => 'yegor/0pdd',
          'default_branch' => 'master'
        }
      }
    )
  end

  def client_raising(method, error)
    response = gitlab_response
    Object.new.tap do |client|
      client.define_singleton_method(method) do |_repo, *_args|
        raise error.new(response) if error < Gitlab::Error::ResponseError # rubocop:disable Style/RaiseArgs
        raise error, 'denied'
      end
    end
  end

  def gitlab_response
    OpenStruct.new(
      code: 403,
      parsed_response: OpenStruct.new(message: 'denied'),
      request: OpenStruct.new(base_uri: 'https://gitlab.com', path: '/api/v4/projects/1')
    )
  end
end
