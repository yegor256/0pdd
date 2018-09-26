require 'nokogiri'
require 'ostruct'
require 'test/unit'
require_relative '../objects/diff'

# Complicated diff test.
class TestDiff < Test::Unit::TestCase

  # @todo #234:15m Add tests for more complicated dynamics, like [here](https://github.com/php-coder/mystamps/issues/695#issuecomment-405372820)

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
    assert(
      tickets.messages.length == 1,
      "Wrong about of msgs (#{tickets.messages.length}): #{tickets.messages}"
    )
    assert(
      tickets.messages[0] ==
      '999 2 puzzles [#100](), [#13]() are still not solved; solved: [#101]().',
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
