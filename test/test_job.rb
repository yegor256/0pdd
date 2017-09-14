# encoding: utf-8

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

require 'nokogiri'
require 'test/unit'
require 'tmpdir'
require_relative 'fake_repo'
require_relative 'fake_tickets'
require_relative 'fake_storage'
require_relative '../objects/job'
require_relative '../objects/safe_storage'

# Job test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2017 Yegor Bugayenko
# License:: MIT
class TestJob < Test::Unit::TestCase
  def test_simple_scenario
    Dir.mktmpdir 'test' do |d|
      Job.new(
        FakeRepo.new,
        SafeStorage.new(FakeStorage.new(d)),
        FakeTickets.new
      ).proceed
    end
  end
end
