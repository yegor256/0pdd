# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'ostruct'
require_relative 'test__helper'
require_relative '../objects/diff'

# Complicated diff test.
class TestDiff < Minitest::Test
  def test_notification_on_parent_solved_with_others_unsolved
    tickets = Tickets.new
    before = Nokogiri::XML(
      '<puzzles>
        <puzzle alive="true">
          <id>100-1</id>
          <issue>100</issue>
          <ticket>999</ticket>
        </puzzle>
        <puzzle alive="true">
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
    after.xpath('//puzzle[id="100-2"]')[0]['alive'] = 'false'
    Diff.new(before, after).notify(tickets)
    assert_equal(
      1, tickets.messages.length,
      "Wrong about of msgs (#{tickets.messages.length}): #{tickets.messages}"
    )
    assert_equal(
      '999 2 puzzles [#100](), [#13]() are still not solved; solved: [#101]().', tickets.messages[0],
      "Text is wrong: #{tickets.messages[0]}"
    )
  end

  def test_notification_on_added_unknown_child_with_solved_siblings
    tickets = Tickets.new
    before = Nokogiri::XML(puzzles_xml)
    after = Nokogiri::XML(puzzles_xml(puzzle_xml('867', 'unknown', true)))
    Diff.new(before, after).notify(tickets)
    assert_equal(
      1, tickets.messages.length,
      "Wrong about of msgs (#{tickets.messages.length}): #{tickets.messages}"
    )
    assert_equal(
      [
        '695 2 puzzles [#839](//issue/839), [#867](//issue/867) are still not solved',
        'solved: [#833](//issue/833).'
      ].join('; '),
      tickets.messages[0],
      "Text is wrong: #{tickets.messages[0]}"
    )
  end

  def puzzles_xml(extra = '')
    <<~XML
      <puzzles>
        <puzzle alive="true">
          <id>695-parent</id>
          <issue>695</issue>
          <children>
            #{puzzle_xml('833', '833', false)}
            #{puzzle_xml('839', '839', true)}
            #{extra}
          </children>
        </puzzle>
      </puzzles>
    XML
  end

  def puzzle_xml(id, issue, alive)
    <<~XML
      <puzzle alive="#{alive}">
        <id>695-#{id}</id>
        <issue href="//issue/#{id}">#{issue}</issue>
        <ticket>695</ticket>
      </puzzle>
    XML
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
