# Copyright (c) 2016-2017 Yegor Bugayenko
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
require 'mocha/test_unit'
require_relative 'test__helper'
require_relative '../objects/sentry_tickets'

# SentryTickets test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2017 Yegor Bugayenko
# License:: MIT
class TestSentryTickets < Test::Unit::TestCase
  def test_exception_catching_on_submit
    tickets = Object.new
    def tickets.submit(_)
      raise 'submit failure'
    end
    Mail::Message.any_instance.stubs(:deliver!)
    assert_raise do
      SentryTickets.new(tickets).submit(0)
    end
  end

  def test_exception_catching_on_close
    tickets = Object.new
    def tickets.close(_)
      raise 'close failure'
    end
    Mail::Message.any_instance.stubs(:deliver!)
    assert_raise do
      SentryTickets.new(tickets).close(0)
    end
  end
end
