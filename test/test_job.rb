# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'tmpdir'
require_relative 'test__helper'
require_relative 'fake_repo'
require_relative 'fake_github'
require_relative 'fake_tickets'
require_relative 'fake_storage'
require_relative '../objects/jobs/job'
require_relative '../objects/storage/safe_storage'

# Job test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2026 Yegor Bugayenko
# License:: MIT
class TestJob < Minitest::Test
  def test_simple_scenario
    Dir.mktmpdir 'test' do |d|
      repo = FakeRepo.new
      vcs = FakeGithub.new(repo: repo)
      Job.new(
        vcs,
        SafeStorage.new(FakeStorage.new(d)),
        FakeTickets.new
      ).proceed
    end
  end
end
