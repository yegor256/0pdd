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

  def test_normalizes_string_features_with_saved_weights
    model = LinearModel.new('0pdd', FakeStorage.new)
    model.instance_variable_get(:@storage).save(
      Array.new(10, 0.0).map.with_index { |w, i| i.zero? ? 1.0 : w }
    )
    assert_equal(
      [1, 2, 0],
      model.predict(
        [
          { 'id' => 'slow', 'estimate' => '30', 'body' => 'slow puzzle', 'time' => '2016-01-21T12:44:55Z' },
          { 'id' => 'fast', 'estimate' => '5', 'body' => 'fast puzzle', 'time' => '2016-01-21T12:45:55Z' },
          { 'id' => 'medium', 'estimate' => '10', 'body' => 'medium puzzle', 'time' => '2016-01-21T12:46:55Z' }
        ]
      )
    )
  end
end
