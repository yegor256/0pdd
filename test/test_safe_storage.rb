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
require 'nokogiri'
require_relative 'test__helper'
require_relative 'fake_storage'
require_relative 'fake_log'
require_relative '../objects/storage/safe_storage'

# SafeStorage test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2025 Yegor Bugayenko
# License:: MIT
class TestSafeStorage < Test::Unit::TestCase
  def test_accepts_valid_xml
    storage = SafeStorage.new(FakeStorage.new)
    storage.save(
      Nokogiri::XML(
        '<?xml version="1.0"?>
        <puzzles xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:noNamespaceSchemaLocation="http://www.0pdd.com/puzzles.xsd"
          date="2016-12-08T12:00:49Z" version="0.0.0">
          <puzzle alive="true">
            <issue>unknown</issue>
            <ticket>1</ticket>
            <estimate>10</estimate>
            <role>DEV</role>
            <id>1-5e0e29d8</id>
            <lines>7-7</lines>
            <body>create mvvm model (see main page) for this page</body>
            <file>attendance/lib/login_page.dart</file>
            <author>@ammaratef45</author>
            <email>a_atef_test@gmail-test.com</email>
            <time>2019-01-16T17:08:45Z</time>
            <children/>
          </puzzle>
        </puzzles>'
      )
    )
  end

  def test_rejects_invalid_xml
    storage = SafeStorage.new(FakeStorage.new)
    assert_raise RuntimeError do
      storage.save(Nokogiri::XML('<test>hello</test>'))
    end
  end
end
