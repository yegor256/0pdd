# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'yaml'
require_relative 'test__helper'
require_relative 'fake_log'
require_relative 'fake_tickets'
require_relative '../objects/tickets/logged_tickets'

# LoggedTickets test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2025 Yegor Bugayenko
# License:: MIT
class TestLoggedTickets < Minitest::Test
  def test_submits_tickets
    log = FakeLog.new
    tickets = LoggedTickets.new('yegor256/0pdd', log, FakeTickets.new)
    tickets.submit(
      Nokogiri::XML(
        '<puzzle>
          <id>23-ab536de</id>
          <file>/a/b/c/test.txt</file>
          <body>hey!</body>
          <lines>1-3</lines>
        </puzzle>'
      ).xpath('/puzzle')
    )
    assert_equal('23-ab536de/submit', log.tag)
    assert_equal(
      '23-ab536de submitted in issue #123: "hey!" at /a/b/c/test.txt; 1-3',
      log.title
    )
  end

  def test_closes_tickets
    log = FakeLog.new
    tickets = LoggedTickets.new('yegor256/0pdd', log, FakeTickets.new)
    tickets.close(
      Nokogiri::XML(
        '<puzzle>
          <id>23-ab536fe</id>
          <issue>1</issue>
        </puzzle>'
      ).xpath('/puzzle')
    )
    assert_equal('23-ab536fe/closed', log.tag)
    assert_equal(
      '23-ab536fe closed in issue #1',
      log.title
    )
  end
end
