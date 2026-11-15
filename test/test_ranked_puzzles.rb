# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'ostruct'
require 'tmpdir'
require_relative 'test__helper'
require_relative 'fake_storage'
require_relative 'fake_tickets'
require_relative '../model/predictor'
require_relative '../objects/ranked_puzzles'

# RankedPuzzles test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2026 Yegor Bugayenko
# License:: MIT
class TestRankedPuzzles < Minitest::Test
  def test_submits_ranked_puzzles_into_puzzles
    Dir.mktmpdir 'test' do |dir|
      tickets = deploy(FakeStorage.new(dir, '<puzzles/>'), nil)
      assert_equal(%w[fast medium slow], tickets.submitted)
      assert_empty(tickets.closed)
    end
  end

  def test_ranks_joined_puzzles_with_stored_ones
    Dir.mktmpdir 'test' do |dir|
      storage = FakeStorage.new(dir, stored_xml)
      tickets = deploy(storage, nil, 'yegor256/0pdd', two_xml)
      assert_equal(
        %w[fast slow],
        tickets.submitted,
        'the new fast puzzle must be submitted before the stored slow one'
      )
    end
  end

  def test_keeps_puzzles_with_issues_unsubmitted
    Dir.mktmpdir 'test' do |dir|
      storage = FakeStorage.new(
        dir,
        <<~XML
          <puzzles>
            <puzzle>
              <ticket>516</ticket>
              <estimate>60</estimate>
              <id>slow</id>
              <body>slow puzzle</body>
              <time>2016-01-21T12:44:55Z</time>
              <issue>42</issue>
            </puzzle>
          </puzzles>
        XML
      )
      tickets = deploy(storage, nil)
      assert_equal(%w[fast medium], tickets.submitted)
    end
  end

  def test_submits_puzzles_with_saved_weights
    Dir.mktmpdir 'test' do |dir|
      weights = FakeWeightsStorage.new('0pdd-ranked', dir)
      weights.save(Array.new(10, 0.0).map.with_index { |w, i| i.zero? ? 1.0 : w })
      tickets = deploy(FakeStorage.new(dir, '<puzzles/>'), weights, '0pdd-ranked')
      assert_equal(
        %w[fast medium slow],
        tickets.submitted,
        'the trained model must rank the puzzles by their estimates'
      )
    end
  end

  def test_trains_and_submits_with_trained_weights
    Dir.mktmpdir 'test' do |dir|
      storage = FakeStorage.new(dir, backlog_xml)
      weights = FakeWeightsStorage.new('0pdd-trained', dir)
      model = LinearModel.new('0pdd-trained', storage, weights)
      model.send(
        :train,
        Predictor.new(layers: [{ name: 'w1', shape: [10, 1] }, { name: 'w2', shape: [1, 1] }])
      ).join
      refute_nil(weights.load, 'the model must save trained weights')
      tickets = deploy(storage, weights, '0pdd-trained')
      assert_equal(
        %w[fast medium slow],
        tickets.submitted.sort,
        'all joined puzzles must be submitted, without index errors'
      )
    end
  end

  private

  def deploy(storage, weights = nil, name = 'yegor256/0pdd', snapshot = snapshot_xml)
    repo = OpenStruct.new(
      name: name,
      xml: Nokogiri.XML(snapshot),
      config: {}
    )
    tickets = FakeTickets.new
    RankedPuzzles.new(repo, storage, weights).deploy(tickets)
    tickets
  end

  def snapshot_xml
    <<~XML
      <puzzles>
        <puzzle>
          <ticket>516</ticket>
          <estimate>60</estimate>
          <id>slow</id>
          <body>slow puzzle</body>
          <time>2016-01-21T12:44:55Z</time>
        </puzzle>
        <puzzle>
          <ticket>516</ticket>
          <estimate>5</estimate>
          <id>fast</id>
          <body>fast puzzle</body>
          <time>2016-01-21T12:45:55Z</time>
        </puzzle>
        <puzzle>
          <ticket>516</ticket>
          <estimate>10</estimate>
          <id>medium</id>
          <body>medium puzzle</body>
          <time>2016-01-21T12:46:55Z</time>
        </puzzle>
      </puzzles>
    XML
  end

  def stored_xml
    <<~XML
      <puzzles>
        <puzzle>
          <ticket>516</ticket>
          <estimate>60</estimate>
          <id>slow</id>
          <body>slow puzzle</body>
          <time>2016-01-21T12:44:55Z</time>
          <issue>unknown</issue>
        </puzzle>
      </puzzles>
    XML
  end

  def two_xml
    <<~XML
      <puzzles>
        <puzzle>
          <ticket>516</ticket>
          <estimate>60</estimate>
          <id>slow</id>
          <body>slow puzzle</body>
          <time>2016-01-21T12:44:55Z</time>
        </puzzle>
        <puzzle>
          <ticket>516</ticket>
          <estimate>5</estimate>
          <id>fast</id>
          <body>fast puzzle</body>
          <time>2016-01-21T12:45:55Z</time>
        </puzzle>
      </puzzles>
    XML
  end

  def backlog_xml
    <<~XML
      <puzzles>
        <puzzle>
          <ticket>515</ticket>
          <estimate>10</estimate>
          <id>515-a</id>
          <body>abc</body>
          <time>2016-01-01T10:00:00Z</time>
          <closed>2016-01-01T12:00:00Z</closed>
        </puzzle>
        <puzzle>
          <ticket>515</ticket>
          <estimate>20</estimate>
          <id>515-b</id>
          <body>abcdef</body>
          <time>2016-01-02T10:00:00Z</time>
          <closed>2016-01-02T13:00:00Z</closed>
        </puzzle>
        <puzzle>
          <ticket>515</ticket>
          <estimate>30</estimate>
          <id>515-c</id>
          <body>abcdefg</body>
          <time>2016-01-03T10:00:00Z</time>
          <closed>2016-01-03T14:00:00Z</closed>
        </puzzle>
      </puzzles>
    XML
  end
end
