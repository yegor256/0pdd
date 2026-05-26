# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative '../objects/vcs/gitlab'

class TestGitlabRepo < Minitest::Test
  def test_wraps_issue_lookup_gitlab_error
    error = gitlab_response_error(Gitlab::Error::Forbidden, 403, 'forbidden')
    raised = assert_raises(RuntimeError) do
      repo_with_error(:issue, error).issue(42)
    end
    assert_includes raised.message, "Can't read GitLab issue 42"
    assert_includes raised.message, 'forbidden'
    refute_includes raised.message, "can' comment"
  end

  def test_wraps_close_issue_gitlab_error
    error = gitlab_response_error(Gitlab::Error::TooManyRequests, 429, 'slow down')
    raised = assert_raises(RuntimeError) do
      repo_with_error(:close_issue, error).close_issue(42)
    end
    assert_includes raised.message, "Can't close GitLab issue 42"
    assert_includes raised.message, 'slow down'
  end

  def test_wraps_add_comment_network_error
    raised = assert_raises(RuntimeError) do
      repo_with_error(:create_issue_note, Net::OpenTimeout.new('timed out')).add_comment(42, 'hello')
    end
    assert_includes raised.message, "Can't comment on GitLab issue 42"
    assert_includes raised.message, 'timed out'
  end

  private

  def repo_with_error(method, error)
    GitlabRepo.new(FailingGitlabClient.new(method, error), gitlab_payload)
  end

  def gitlab_payload
    {
      'project' => {
        'url' => 'https://gitlab.com/acme/widgets',
        'path_with_namespace' => 'acme/widgets',
        'default_branch' => 'master'
      },
      'ref' => 'master',
      'checkout_sha' => 'abc123'
    }
  end

  def gitlab_response_error(klass, code, message)
    klass.new(GitlabErrorResponse.new(code, message))
  end

  class FailingGitlabClient
    def initialize(method, error)
      @method = method
      @error = error
    end

    def issue(*)
      raise @error if @method == :issue
    end

    def close_issue(*)
      raise @error if @method == :close_issue
    end

    def create_issue_note(*)
      raise @error if @method == :create_issue_note
    end
  end

  class GitlabErrorResponse
    attr_reader :code, :request

    def initialize(code, message)
      @code = code
      @message = message
      @request = OpenStruct.new(base_uri: 'https://gitlab.example', path: '/api/v4/projects/1')
    end

    def parsed_response
      OpenStruct.new(message: @message)
    end
  end
end
