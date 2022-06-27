# Copyright (c) 2016-2022 Yegor Bugayenko
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
