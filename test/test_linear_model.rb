# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'tmpdir'
require_relative 'test__helper'
require_relative 'fake_storage'
require_relative 'fake_tickets'
require_relative '../model/linear'

# LinearModel test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2026 Yegor Bugayenko
# License:: MIT
class TestLinearModel < Minitest::Test
  def test_ranks_puzzles_by_estimate
    assert_equal(
      [1, 2, 0],
      LinearModel.new(
        'yegor256/0pdd',
        FakeStorage.new
      ).predict(
        [
          { 'id' => 'slow', 'estimate' => '30', 'body' => 'slow puzzle' },
          { 'id' => 'fast', 'estimate' => '5', 'body' => 'fast puzzle' },
          { 'id' => 'medium', 'estimate' => '10', 'body' => 'medium puzzle' }
        ]
      )
    )
  end

  def test_returns_positional_indexes_when_weights_are_loaded
    model = LinearModel.new('0pdd', FakeStorage.new)
    model.instance_variable_get(:@storage).save(
      Array.new(10, 0.0).map.with_index { |w, i| i.zero? ? -1.0 : w }
    )
    assert_equal(
      [0, 2, 1],
      model.predict(
        [
          { 'id' => 'slow', 'estimate' => '30', 'body' => 'slow puzzle', 'time' => '2016-01-21T12:44:55Z' },
          { 'id' => 'fast', 'estimate' => '5', 'body' => 'fast puzzle', 'time' => '2016-01-21T12:45:55Z' },
          { 'id' => 'medium', 'estimate' => '10', 'body' => 'medium puzzle', 'time' => '2016-01-21T12:46:55Z' }
        ]
      )
    )
  end

  def test_ranks_puzzles_in_snapshot
    snapshot = Nokogiri.XML(puzzles_xml)
    repo = OpenStruct.new(name: 'yegor256/0pdd', xml: snapshot, config: {})
    ranked = RankedPuzzles::RankedRepo.new(repo, FakeStorage.new).xml
    assert_equal(
      %w[fast medium slow],
      ranked.xpath('//puzzle/id').map(&:text)
    )
  end

  def test_submits_ranked_puzzles_into_puzzles
    Dir.mktmpdir 'test' do |dir|
      repo = OpenStruct.new(
        name: 'yegor256/0pdd',
        xml: Nokogiri.XML(puzzles_xml),
        config: {}
      )
      storage = FakeStorage.new(dir, Nokogiri.XML('<puzzles/>'))
      tickets = FakeTickets.new
      RankedPuzzles.new(repo, storage).deploy(tickets)
      assert_equal(%w[fast medium slow], tickets.submitted)
      assert_empty(tickets.closed)
    end
  end

  private

  def puzzles_xml
    <<~XML
      <puzzles>
        <puzzle>
          <id>slow</id>
          <estimate>60</estimate>
          <body>slow puzzle</body>
        </puzzle>
        <puzzle>
          <id>fast</id>
          <estimate>5</estimate>
          <body>fast puzzle</body>
        </puzzle>
        <puzzle>
          <id>medium</id>
          <estimate>10</estimate>
          <body>medium puzzle</body>
        </puzzle>
      </puzzles>
    XML
  end
end
