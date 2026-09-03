# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative '../objects/vcs/gitlab'

# GitLab repo test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2026 Yegor Bugayenko
# License:: MIT
class TestGitlabRepo < Minitest::Test
  def test_identifies_vcs
    repo = GitlabRepo.new(
      nil,
      {
        'checkout_sha' => 'a1b2c3',
        'project' => {
          'url' => 'git@gitlab.com:yegor256/0pdd.git',
          'path_with_namespace' => 'yegor256/0pdd',
          'default_branch' => 'master'
        },
        'ref' => 'refs/heads/master'
      }
    )
    assert_equal('gitlab', repo.name)
  end
end
