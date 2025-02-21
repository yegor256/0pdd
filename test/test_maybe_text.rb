# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'test/unit'
require_relative 'test__helper'
require_relative '../objects/maybe_text'

# Truncated test.
class TestMaybeText < Test::Unit::TestCase
  def test_nil_input_then_blank
    assert_equal('', MaybeText.new('output', nil).to_s)
  end

  def test_empty_input_then_blank
    assert_equal('', MaybeText.new('output', '').to_s)
  end

  def test_excluded_input_then_blank
    assert_equal('', MaybeText.new('output', 'exc', exclude_if: 'exc').to_s)
  end

  def test_present_input_then_output
    assert_equal('output', MaybeText.new('output', 'input').to_s)
  end

  def test_show_output_when_exclude_if_is_present
    assert_equal('output', MaybeText.new('output', 'input', exclude_if: 'output').to_s)
  end
end
