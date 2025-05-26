# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative '../objects/truncated'

# Truncated test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2025 Yegor Bugayenko
# License:: MIT
class TestTruncated < Minitest::Test
  def test_simple_formatting
    assert_equal('How...', Truncated.new('How are you?', 7).to_s)
  end

  def test_very_long_text
    assert_equal(
      'How are...',
      Truncated.new('How are you? How are you? How are you? How are you?', 13).to_s
    )
  end

  def test_short_long_text
    assert_equal('Hey', Truncated.new('Hey', 13).to_s)
  end

  def test_unicode_text
    assert_equal(
      'Как дела?...',
      Truncated.new("Как дела?\n Как дела? \nКак дела? \n Как дела?\n", 13).to_s
    )
  end

  def test_multi_line_text
    assert_equal(
      'First line Second...',
      Truncated.new("  First   line  \n  Second   line\nThird line  ", 23).to_s
    )
  end
end
