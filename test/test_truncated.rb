# Copyright (c) 2016-2025 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'test/unit'
require_relative 'test__helper'
require_relative '../objects/truncated'

# Truncated test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2025 Yegor Bugayenko
# License:: MIT
class TestTruncated < Test::Unit::TestCase
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
