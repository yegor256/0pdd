# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'yaml'
require_relative 'test__helper'
require_relative '../objects/tickets/commit_tickets'

# CommitTickets test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2026 Yegor Bugayenko
# License:: MIT
class TestCommitTickets < Minitest::Test
  def test_submits_tickets
    config = YAML.safe_load(
      "
alerts:
  suppress:
    - on-found-puzzle"
    )
    vcs = object(repo: { config: config })
    tickets = Object.new
    def tickets.submit(_)
      {}
    end
    tickets = CommitTickets.new(vcs, tickets)
    tickets.submit(nil)
  end

  def test_closes_tickets
    config = YAML.safe_load(
      "
alerts:
  suppress:
    - on-lost-puzzle"
    )
    vcs = object(repo: { config: config })
    tickets = Object.new
    def tickets.close(_)
      {}
    end
    tickets = CommitTickets.new(vcs, tickets)
    tickets.close(nil)
  end

  def test_scope_suppressed_repo_should_be_quiet
    config = YAML.safe_load(
      "
alerts:
  suppress:
    - on-found-puzzle"
    )
    vcs = object(repo: { config: config })
    tickets = Object.new
    def tickets.submit(_)
      {}
    end
    tickets = CommitTickets.new(vcs, tickets)
    tickets.submit(nil)
  end
end
