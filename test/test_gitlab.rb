# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative '../objects/clients/gitlab'

# Github test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2025 Yegor Bugayenko
# License:: MIT
class TestGitlab < Minitest::Test
  def test_configures_everything_right
    gitlab = GitlabClient.new.client
    assert_raises Gitlab::Error::MissingCredentials do
      gitlab.user('0pdd')['username']
    end
  end
end
