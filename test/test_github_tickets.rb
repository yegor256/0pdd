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
require 'nokogiri'
require 'yaml'
require_relative '../objects/github_tickets'

# GithubTickets test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2017 Yegor Bugayenko
# License:: MIT
class TestGithubTickets < Test::Unit::TestCase
  def test_submits_tickets
    sources = Object.new
    def sources.config
      YAML.safe_load("alerts:\n  github:\n    - yegor256\n    - davvd")
    end
    require_relative 'test__helper'
    tickets = GithubTickets.new('yegor256/0pdd', FakeGithub.new, sources)
    tickets.submit(
      Nokogiri::XML(
        '<puzzle>
          <id>23-ab536de</id>
          <file>/a/b/c/test.txt</file>
          <body>hey!</body>
          <lines>1-3</lines>
        </puzzle>'
      ).xpath('/puzzle')
    )
  end

  def test_closes_tickets
    sources = Object.new
    def sources.config
      YAML.safe_load("alerts:\n  github:\n    - yegor256\n    - davvd")
    end
    require_relative 'test__helper'
    tickets = GithubTickets.new('yegor256/0pdd', FakeGithub.new, sources)
    tickets.close(Nokogiri::XML('<puzzle><issue>1</issue></puzzle>'))
  end
end
