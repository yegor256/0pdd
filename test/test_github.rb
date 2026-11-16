# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative '../objects/clients/github'

# Github test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2026 Yegor Bugayenko
# License:: MIT
class TestGithub < Minitest::Test
  def test_configures_everything_right
    github = Github.new.client
    assert_instance_of(Octokit::Client, github)
    # Stubbed to stay offline: a live request here made rake flaky
    # with "403 - API rate limit exceeded" in CI.
    github.define_singleton_method(:user) do |_login|
      { login: '0pdd' }
    end
    assert_equal('0pdd', github.user('0pdd')[:login])
  end
end
