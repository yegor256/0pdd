# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'ostruct'
require 'tmpdir'
require_relative 'test__helper'
require_relative 'fake_storage'
require_relative '../objects/ranking_repo'

# RankingRepo test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2026 Yegor Bugayenko
# License:: MIT
class TestRankingRepo < Minitest::Test
  def test_moves_submission_candidates_by_rank
    Dir.mktmpdir 'test' do |dir|
      weights = FakeWeightsStorage.new('0pdd-ranking-repo', dir)
      weights.save(Array.new(10, 0.0).map.with_index { |w, i| i.zero? ? 1.0 : w })
      ranked = RankingRepo.new(
        OpenStruct.new(name: '0pdd-ranking-repo'),
        FakeStorage.new(dir),
        weights
      ).rank(joined_xml)
      assert_equal(
        %w[fast slow],
        ranked.xpath('//puzzle[@alive="true"]/id').map(&:text),
        'the fast puzzle must go before the stored slow one'
      )
    end
  end

  def test_keeps_puzzles_with_issues_in_place
    Dir.mktmpdir 'test' do |dir|
      weights = FakeWeightsStorage.new('0pdd-ranking-repo-fixed', dir)
      weights.save(Array.new(10, 0.0).map.with_index { |w, i| i.zero? ? 1.0 : w })
      ranked = RankingRepo.new(
        OpenStruct.new(name: '0pdd-ranking-repo-fixed'),
        FakeStorage.new(dir),
        weights
      ).rank(joined_xml)
      assert_equal(
        %w[fixed fast slow],
        ranked.xpath('//puzzle/id').map(&:text),
        'the puzzle with a ticket must stay where it is'
      )
    end
  end

  def test_ignores_documents_without_candidates
    xml = Nokogiri.XML('<puzzles><puzzle alive="false"><id>gone</id><issue>1</issue></puzzle></puzzles>')
    ranked = RankingRepo.new(
      OpenStruct.new(name: '0pdd-ranking-repo-empty'),
      FakeStorage.new
    ).rank(xml)
    assert_equal(%w[gone], ranked.xpath('//puzzle/id').map(&:text))
  end

  private

  def joined_xml
    Nokogiri.XML(
      <<~XML
        <puzzles>
          <puzzle alive="true">
            <ticket>516</ticket>
            <estimate>60</estimate>
            <id>slow</id>
            <body>slow puzzle</body>
            <time>2016-01-21T12:44:55Z</time>
            <issue>unknown</issue>
          </puzzle>
          <puzzle alive="false">
            <ticket>515</ticket>
            <estimate>30</estimate>
            <id>fixed</id>
            <body>fixed puzzle</body>
            <time>2016-01-21T12:46:55Z</time>
            <issue>42</issue>
          </puzzle>
          <puzzle alive="true">
            <ticket>516</ticket>
            <estimate>5</estimate>
            <id>fast</id>
            <body>fast puzzle</body>
            <time>2016-01-21T12:45:55Z</time>
            <issue>unknown</issue>
          </puzzle>
        </puzzles>
      XML
    )
  end
end
