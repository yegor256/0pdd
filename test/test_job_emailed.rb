# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'veil'
require_relative 'test__helper'
require_relative 'fake_repo'
require_relative 'fake_github'
require_relative '../objects/jobs/job_emailed'

# JobEmailed test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2025 Yegor Bugayenko
# License:: MIT
class TestJobEmailed < Minitest::Test
  def fake_job
    Veil.new(Object.new, proceed: nil)
  end

  def test_simple_scenario
    repo = FakeRepo.new
    vcs = FakeGithub.new(repo: repo)
    job = fake_job
    JobEmailed.new(vcs, job).proceed
  end

  def test_exception_mail_to_repo_owner_as_cc
    skip('this test needs proper mocking')
    repo = FakeRepo.new
    vcs = FakeGithub.new(repo: repo)
    job = fake_job
    assert_raises(StandardError) do
      JobEmailed.new(vcs, job).proceed
    end
  end
end
