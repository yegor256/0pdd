# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'test/unit'
require_relative 'test__helper'
require_relative '../objects/jobs/job_detached'

# JobDetached test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2025 Yegor Bugayenko
# License:: MIT
class TestJobDetached < Test::Unit::TestCase
  def test_simple_scenario
    job = Object.new
    def job.proceed
      # nothing
    end
    require_relative 'fake_repo'
    vcs = object(repo: nil)
    vcs.repo = FakeRepo.new
    JobDetached.new(vcs, job).proceed
  end
end
