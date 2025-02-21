# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'test/unit'
require 'mocha/test_unit'
require_relative 'test__helper'
require_relative '../objects/jobs/job_commiterrors'

# JobCommitErrors test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2025 Yegor Bugayenko
# License:: MIT
class TestJobCommitErrors < Test::Unit::TestCase
  class Stub
    attr_reader :name, :reported, :repo

    def initialize(repo)
      @repo = repo
      @name = 'GITHUB'
    end

    def create_commit_comment(_, text)
      @reported = text
    end
  end

  def test_timeout_scenario
    job = Object.new
    def job.proceed
      raise 'Intended to be here'
    end
    vcs = Stub.new(object(head_commit_hash: '123'))
    begin
      JobCommitErrors.new(vcs, job).proceed
    rescue StandardError => e
      assert(!e.nil?)
    end
    assert(!vcs.reported.empty?)
  end
end
