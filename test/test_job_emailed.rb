# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'test/unit'
require 'mocha/test_unit'
require_relative 'test__helper'
require_relative 'fake_repo'
require_relative 'fake_github'
require_relative '../objects/jobs/job_emailed'

# JobEmailed test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2025 Yegor Bugayenko
# License:: MIT
class TestJobEmailed < Test::Unit::TestCase
  def fake_job
    job = stub
    job.stubs(:proceed)
    job
  end

  def test_simple_scenario
    repo = FakeRepo.new
    vcs = FakeGithub.new(repo: repo)
    job = fake_job
    JobEmailed.new(vcs, job).proceed
  end

  def test_exception_mail_to_repo_owner_as_cc
    exception_class = Exception
    repo = FakeRepo.new
    vcs = FakeGithub.new(repo: repo)
    job = fake_job
    job.expects(:proceed).raises(exception_class)
    Mail::Message.any_instance.stubs(:deliver!)
    Mail::Message.any_instance.expects(:cc=).with('foobar@example.com')
    assert_raise Exception do
      JobEmailed.new(vcs, job).proceed
    end
  end
end
