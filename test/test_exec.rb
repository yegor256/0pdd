# Copyright (c) 2016-2023 Yegor Bugayenko
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
require_relative '../objects/exec'
require_relative '../objects/user_error'

# Exec test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2023 Yegor Bugayenko
# License:: MIT
class TestExec < Test::Unit::TestCase
  def test_simple_bash_call
    assert(Exec.new('echo 123').run.start_with?("123\n"))
  end

  def test_hides_stderr
    assert(Exec.new('set +x; echo hello').run.start_with?('hello'))
  end

  def test_bash_failure
    assert_raises Exec::Error do
      Exec.new('how_are_you').run
    end
  end

  def test_failures_with_user_error
    error = assert_raises Exec::Error do
      Exec.new('exit 1').run
    end
    assert_equal(1, error.code)
  end
end
