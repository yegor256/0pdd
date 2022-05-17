# Copyright (c) 2016-2022 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'test/unit'
require 'nokogiri'
require 'yaml'
require_relative 'test__helper'
require_relative 'fake_log'
require_relative 'fake_tickets'
require_relative '../objects/tickets/logged_tickets'

# LoggedTickets test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2022 Yegor Bugayenko
# License:: MIT
class TestLoggedTickets < Test::Unit::TestCase
  def test_submits_tickets
    log = FakeLog.new
    tickets = LoggedTickets.new(log, 'yegor256/0pdd', FakeTickets.new)
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
    tickets = LoggedTickets.new(log, 'yegor256/0pdd', FakeTickets.new)
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
