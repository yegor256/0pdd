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

require 'test/unit'
require_relative 'fake_storage'
require_relative '../objects/once_storage'

# OnceStorage test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2017 Yegor Bugayenko
# License:: MIT
class TestOnceStorage < Test::Unit::TestCase
  def test_never_saves_duplicates
    origin = TestStorage.new
    storage = OnceStorage.new(origin)
    storage.save(Nokogiri::XML('<test>hello</test>'))
    assert_equal(0, origin.count)
  end

  def test_saves_only_once
    origin = TestStorage.new
    storage = OnceStorage.new(origin)
    storage.save(Nokogiri::XML('<test>bye</test>'))
    assert_equal(1, origin.count)
  end

  class TestStorage
    attr_reader :count

    def initialize
      @count = 0
    end

    def load
      Nokogiri::XML('<test>hello</test>')
    end

    def save(_)
      @count += 1
    end
  end
end
