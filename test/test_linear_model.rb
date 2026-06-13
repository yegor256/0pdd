# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative 'fake_storage'
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
end
