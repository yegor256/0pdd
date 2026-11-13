# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'ostruct'
require 'tmpdir'
require_relative 'test__helper'
require_relative 'fake_storage'
require_relative 'fake_tickets'
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

  private

  def deploy(config:)
    snapshot = Nokogiri.XML(
      '<puzzles>
        <puzzle>
          <id>516-ffdd7ae8</id><estimate>60</estimate><body>slow puzzle</body>
        </puzzle>
        <puzzle>
          <id>517-ffdd7ae9</id><estimate>15</estimate><body>fast puzzle</body>
        </puzzle>
        <puzzle>
          <id>518-ffdd7aea</id><estimate>30</estimate><body>medium puzzle</body>
        </puzzle>
      </puzzles>'
    )
    repo = OpenStruct.new(name: 'yegor256/0pdd', xml: snapshot, config: config)
    tickets = FakeTickets.new
    Dir.mktmpdir 'test' do |dir|
      MaybeRankedPuzzles.new(repo, FakeStorage.new(dir, '<puzzles/>')).deploy(tickets)
    end
    tickets
  end
end
