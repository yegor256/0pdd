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
    assert_equal('0pdd', github.user('0pdd')[:login],
                 "Real user is #{github.user('0pdd')[:login]}")
  end
end
