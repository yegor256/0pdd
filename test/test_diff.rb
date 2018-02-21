# Copyright (c) 2016-2018 Yegor Bugayenko
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

require 'nokogiri'
require 'ostruct'
require 'test/unit'
require_relative '../objects/diff'

# Diff test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2018 Yegor Bugayenko
# License:: MIT
class TestDiff < Test::Unit::TestCase
  def test_notification_on_new_puzzles
    tickets = Tickets.new
    Diff.new(
      Nokogiri::XML('<puzzles/>'),
      Nokogiri::XML(
        '<puzzles>
          <puzzle alive="true">
            <id>1-abcdef</id>
            <issue>5</issue>
            <children>
              <puzzle alive="true">
                <id>5-abcdef</id>
                <issue href="#">6</issue>
                <children>
                </children>
              </puzzle>
            </children>
          </puzzle>
        </puzzles>'
      )
    ).notify(tickets)
    assert(tickets.messages.length == 2)
    assert(
      tickets.messages[0] == '5 this puzzle is still not solved: [6](#)',
      "Text is wrong: #{tickets.messages[0]}"
    )
    assert(
      tickets.messages[1] == '6 all puzzles are solved',
      "Text is wrong: #{tickets.messages[1]}"
    )
  end

  def test_notification_on_update
    tickets = Tickets.new
    Diff.new(
      Nokogiri::XML(
        '<puzzles>
          <puzzle alive="true">
            <id>1-abcdef</id>
            <issue>5</issue>
            <children>
              <puzzle alive="true">
                <id>5-abcdef</id>
                <issue href="#">6</issue>
              </puzzle>
            </children>
          </puzzle>
        </puzzles>'
      ),
      Nokogiri::XML(
        '<puzzles>
          <puzzle alive="true">
            <id>1-abcdef</id>
            <issue>5</issue>
            <children>
              <puzzle alive="false">
                <id>5-abcdef</id>
                <issue href="#">6</issue>
              </puzzle>
            </children>
          </puzzle>
        </puzzles>'
      )
    ).notify(tickets)
    assert(tickets.messages.length == 2)
    assert(
      tickets.messages[0] == '5 all puzzles are solved',
      "Text is wrong: #{tickets.messages[0]}"
    )
  end

  class Tickets
    attr_reader :messages
    def initialize
      @messages = []
    end

    def notify(ticket, text)
      @messages << "#{ticket} #{text}"
    end
  end
end
