# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'ostruct'
require_relative 'test__helper'
require_relative '../objects/diff'

# Diff test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2025 Yegor Bugayenko
# License:: MIT
class TestDiff < Minitest::Test
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
    assert_equal(
      1, tickets.messages.length,
      "Incorrect number of messages: #{tickets.messages.length}"
    )
    assert_equal(
      '5 the puzzle [#6](#) is still not solved.', tickets.messages[0],
      "Text is wrong: #{tickets.messages[0]}"
    )
  end

  def test_notification_unknown_issue
    tickets = Tickets.new
    xml = File.open('test-assets/puzzles/notify-unknown-open-issues.xml') do |f|
      Nokogiri::XML(f)
    end
    Diff.new(Nokogiri::XML('<puzzles/>'), xml).notify(tickets)
    assert_equal(
      1, tickets.messages.length,
      "Incorrect number of messages: #{tickets.messages.length}"
    )
    assert_equal(
      '5 the puzzle [#125](//issue/125) is still not solved.', tickets.messages[0],
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
    assert_equal(
      1, tickets.messages.length,
      "Incorrect number of messages: #{tickets.messages.length}"
    )
    assert_equal(
      '55 2 puzzles [#66](#), [#77](#) are still not solved.', tickets.messages[0],
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
    assert_equal(
      1, tickets.messages.length,
      "Incorrect number of messages: #{tickets.messages.length}"
    )
    assert_equal(
      '500 the only puzzle [#100]() is solved here.', tickets.messages[0],
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
    assert_equal(
      1, tickets.messages.length,
      "Wrong about of msgs (#{tickets.messages.length}): #{tickets.messages}"
    )
    assert_equal(
      '999 the puzzle [#13]() is still not solved; solved: [#100](), [#101]().', tickets.messages[0],
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
    assert_equal(
      1, tickets.messages.length,
      "Wrong about of msgs (#{tickets.messages.length}): #{tickets.messages}"
    )
    assert_equal(
      '5 the only puzzle [#6](#) is solved here.', tickets.messages[0],
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
    assert_empty(tickets.messages)
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
