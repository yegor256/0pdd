# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'ostruct'
require 'tmpdir'
require_relative 'test__helper'
require_relative 'fake_storage'
require_relative 'fake_tickets'
require_relative '../model/predictor'
require_relative '../objects/maybe_ranked_puzzles'

# MaybeRankedPuzzles test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2026 Yegor Bugayenko
# License:: MIT
class TestMaybeRankedPuzzles < Minitest::Test
  def test_ranks_puzzles_when_model_is_on
    assert_equal(
      %w[517-ffdd7ae9 518-ffdd7aea 516-ffdd7ae8],
      deploy(config: { 'model' => true }).submitted
    )
  end

  def test_keeps_order_when_model_is_off
    assert_equal(
      %w[516-ffdd7ae8 517-ffdd7ae9 518-ffdd7aea],
      deploy(config: {}).submitted
    )
  end

  def test_ranks_joined_puzzles_with_stored_ones
    assert_equal(
      %w[517-ffdd7ae9 516-ffdd7ae8],
      deploy(config: { 'model' => true }, stored: stored_xml, snapshot: two_xml).submitted,
      'the new fast puzzle must be submitted before the stored slow one'
    )
  end

  def test_keeps_stored_puzzles_first_when_model_is_off
    assert_equal(
      %w[516-ffdd7ae8 517-ffdd7ae9],
      deploy(config: {}, stored: stored_xml, snapshot: two_xml).submitted
    )
  end

  def test_deploys_ranked_puzzles_with_saved_weights
    Dir.mktmpdir 'test' do |dir|
      weights = FakeWeightsStorage.new('0pdd-saved-weights', dir)
      weights.save(Array.new(10, 0.0).map.with_index { |w, i| i.zero? ? 1.0 : w })
      repo = OpenStruct.new(
        name: '0pdd-saved-weights',
        xml: Nokogiri.XML(two_named_xml),
        config: { 'model' => true }
      )
      tickets = FakeTickets.new
      MaybeRankedPuzzles.new(repo, FakeStorage.new(dir), weights).deploy(tickets)
      assert_equal(
        %w[fast slow],
        tickets.submitted,
        'the trained model must rank the puzzles by their estimates'
      )
    end
  end

  def test_trains_and_deploys_with_trained_weights
    Dir.mktmpdir 'test' do |dir|
      storage = FakeStorage.new(dir, backlog_xml)
      weights = FakeWeightsStorage.new('0pdd-trained', dir)
      model = LinearModel.new('0pdd-trained', storage, weights)
      model.send(
        :train,
        Predictor.new(layers: [{ name: 'w1', shape: [10, 1] }, { name: 'w2', shape: [1, 1] }])
      ).join
      refute_nil(weights.load, 'the model must save trained weights')
      repo = OpenStruct.new(
        name: '0pdd-trained',
        xml: Nokogiri.XML(two_named_xml),
        config: { 'model' => true }
      )
      tickets = FakeTickets.new
      MaybeRankedPuzzles.new(repo, storage, weights).deploy(tickets)
      assert_equal(
        %w[fast slow],
        tickets.submitted.sort,
        'all joined puzzles must be submitted, without index errors'
      )
    end
  end

  private

  def deploy(config:, stored: '<puzzles/>', snapshot: snapshot_xml, name: 'yegor256/0pdd')
    snapshot = Nokogiri.XML(snapshot)
    repo = OpenStruct.new(name: name, xml: snapshot, config: config)
    tickets = FakeTickets.new
    Dir.mktmpdir 'test' do |dir|
      MaybeRankedPuzzles.new(repo, FakeStorage.new(dir, stored)).deploy(tickets)
    end
    tickets
  end

  def snapshot_xml
    <<~XML
      <puzzles>
        <puzzle>
          <id>516-ffdd7ae8</id><estimate>60</estimate><body>slow puzzle</body>
        </puzzle>
        <puzzle>
          <id>517-ffdd7ae9</id><estimate>15</estimate><body>fast puzzle</body>
        </puzzle>
        <puzzle>
          <id>518-ffdd7aea</id><estimate>30</estimate><body>medium puzzle</body>
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
          <id>516-ffdd7ae8</id>
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
          <id>516-ffdd7ae8</id><estimate>60</estimate><body>slow puzzle</body>
        </puzzle>
        <puzzle>
          <id>517-ffdd7ae9</id><estimate>5</estimate><body>fast puzzle</body>
        </puzzle>
      </puzzles>
    XML
  end

  def two_named_xml
    <<~XML
      <puzzles>
        <puzzle>
          <id>slow</id><estimate>60</estimate><body>slow puzzle</body><time>2016-01-21T12:44:55Z</time>
        </puzzle>
        <puzzle>
          <id>fast</id><estimate>5</estimate><body>fast puzzle</body><time>2016-01-21T12:45:55Z</time>
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
