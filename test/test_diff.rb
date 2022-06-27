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

require 'nokogiri'
require 'ostruct'
require 'test/unit'
require_relative '../objects/diff'

# Diff test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2022 Yegor Bugayenko
# License:: MIT
class TestDiff < Test::Unit::TestCase
  def test_notification_on_one_new_puzzle
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
                <ticket>5</ticket>
                <children>
                </children>
              </puzzle>
            </children>
          </puzzle>
        </puzzles>'
      )
    ).notify(tickets)
    assert(
      tickets.messages.length == 1,
      "Incorrect number of messages: #{tickets.messages.length}"
    )
    assert(
      tickets.messages[0] == '5 the puzzle [#6](#) is still not solved.',
      "Text is wrong: #{tickets.messages[0]}"
    )
  end

  def test_notification_on_two_new_puzzles
    tickets = Tickets.new
    Diff.new(
      Nokogiri::XML('<puzzles/>'),
      Nokogiri::XML(
        '<puzzles>
          <puzzle alive="true">
            <id>1-abcdef</id>
            <issue>55</issue>
            <children>
              <puzzle alive="true">
                <id>5-abcdee</id>
                <issue href="#">66</issue>
                <ticket>55</ticket>
                <children>
                </children>
              </puzzle>
              <puzzle alive="true">
                <id>5-abcded</id>
                <issue href="#">77</issue>
                <ticket>55</ticket>
                <children>
                </children>
              </puzzle>
            </children>
          </puzzle>
        </puzzles>'
      )
    ).notify(tickets)
    assert(
      tickets.messages.length == 1,
      "Incorrect number of messages: #{tickets.messages.length}"
    )
    assert(
      tickets.messages[0] ==
      '55 2 puzzles [#66](#), [#77](#) are still not solved.',
      "Text is wrong: #{tickets.messages[0]}"
    )
  end

  def test_notification_on_solved_puzzle
    tickets = Tickets.new
    before = Nokogiri::XML(
      '<puzzles>
        <puzzle alive="true">
          <id>100-ffffff</id>
          <issue>100</issue>
          <ticket>500</ticket>
        </puzzle>
      </puzzles>'
    )
    after = Nokogiri::XML(before.to_s)
    after.xpath('//puzzle[id="100-ffffff"]')[0]['alive'] = 'false'
    Diff.new(before, after).notify(tickets)
    assert(
      tickets.messages.length == 1,
      "Incorrect number of messages: #{tickets.messages.length}"
    )
    assert(
      tickets.messages[0] ==
      '500 the only puzzle [#100]() is solved here.',
      "Text is wrong: #{tickets.messages[0]}"
    )
  end

  def test_notification_on_one_solved_puzzle
    tickets = Tickets.new
    before = Nokogiri::XML(
      '<puzzles>
        <puzzle alive="true">
          <id>100-1</id>
          <issue>100</issue>
          <ticket>999</ticket>
        </puzzle>
        <puzzle alive="false">
          <id>100-2</id>
          <issue>101</issue>
          <ticket>999</ticket>
          <children>
            <puzzle alive="true">
              <id>101-1</id>
              <issue>13</issue>
              <ticket>101</ticket>
            </puzzle>
          </children>
        </puzzle>
      </puzzles>'
    )
    after = Nokogiri::XML(before.to_s)
    after.xpath('//puzzle[id="100-1"]')[0]['alive'] = 'false'
    Diff.new(before, after).notify(tickets)
    assert(
      tickets.messages.length == 1,
      "Wrong about of msgs (#{tickets.messages.length}): #{tickets.messages}"
    )
    assert(
      tickets.messages[0] ==
      '999 the puzzle [#13]() is still not solved; solved: [#100](), [#101]().',
      "Text is wrong: #{tickets.messages[0]}"
    )
  end

  def test_notification_on_update
    tickets = Tickets.new
    before = Nokogiri::XML(
      '<puzzles>
        <puzzle alive="true">
          <id>1-abcdef</id>
          <issue>5</issue>
          <children>
            <puzzle alive="true">
              <id>5-abcdef</id>
              <issue href="#">6</issue>
              <ticket>5</ticket>
            </puzzle>
          </children>
        </puzzle>
      </puzzles>'
    )
    after = Nokogiri::XML(before.to_s)
    after.xpath('//puzzle[id="5-abcdef"]')[0]['alive'] = 'false'
    Diff.new(before, after).notify(tickets)
    assert(
      tickets.messages.length == 1,
      "Wrong about of msgs (#{tickets.messages.length}): #{tickets.messages}"
    )
    assert(
      tickets.messages[0] == '5 the only puzzle [#6](#) is solved here.',
      "Text is wrong: #{tickets.messages[0]}"
    )
  end

  def test_quiet_when_no_changes
    tickets = Tickets.new
    xml = '<puzzles>
      <puzzle alive="true">
        <id>1-abcdef</id>
        <issue>50</issue>
        <children>
          <puzzle alive="true">
            <id>50-abcdef</id>
            <issue href="#">60</issue>
            <children>
            </children>
          </puzzle>
        </children>
      </puzzle>
    </puzzles>'
    Diff.new(
      Nokogiri::XML(xml),
      Nokogiri::XML(xml)
    ).notify(tickets)
    assert(tickets.messages.empty?)
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
