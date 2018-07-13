# Copyright (c) 2016-2018 Yegor Bugayenko
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
require 'fake_github'
require_relative 'test__helper'
require_relative '../objects/milestone_tickets'

# MilestoneTickets test.
# Author:: George Aristy (george.aristy@gmail.com)
# Copyright:: Copyright (c) 2016-2018 Yegor Bugayenko
# License:: MIT
class TestGithubTickets < Test::Unit::TestCase
  def test_sets_milestone
    milestone = 123
    sources = Object.new
    def sources.config
      YAML.safe_load(
        "
tickets:
  - inherit-milestone
alerts:
  suppress:
    - on-inherited-milestone
"
      )
    end
    github = FakeGithub.new
    def github.issue(_, _)
      { "milestone" => { "number" => milestone, "title" => "v1.0" } }
    end
    def github.update_issue(_, _, options)
      @milestone = options['milestone']
    end
    class << github
      attr_accessor :milestone
    end
    tickets = Object.new
    def tickets.submit(puzzle)
      { number: 123, href: 'http://0pdd.com' }
    end
    test = MilestoneTickets.new('yegor256/0pdd', sources, github, tickets)
    test.submit(
      Nokogiri::XML(
        '<puzzle>
          <id>23-ab536de</id>
          <file>/a/b/c/test.txt</file>
          <time>01-01-2017</time>
          <author>yegor</author>
          <body>привет дорогой друг, как твои дела?</body>
          <ticket>123</ticket>
          <estimate>30</estimate>
          <role>DEV</role>
          <lines>1-3</lines>
        </puzzle>'
      ).xpath('/puzzle')
    )
    assert_equal(milestone, github.milestone)
  end
  
  def test_does_not_set_milestone
    sources = Object.new
    def sources.config
      YAML.safe_load("")
    end
    github = FakeGithub.new
    def github.issue(_, _)
      { "milestone" => { "number" => 123, "title" => "v1.0" } }
    end
    def github.update_issue(_, _, options)
      @updated = true
    end
    class << github
      attr_accessor :updated
    end
    tickets = Object.new
    def tickets.submit(puzzle)
      { number: '123', href: 'http://0pdd.com' }
    end
    test = MilestoneTickets.new('yegor256/0pdd', sources, github, tickets)
    test.submit(
      Nokogiri::XML(
        '<puzzle>
          <id>23-ab536de</id>
          <file>/a/b/c/test.txt</file>
          <time>01-01-2017</time>
          <author>yegor</author>
          <body>привет дорогой друг, как твои дела?</body>
          <ticket>123</ticket>
          <estimate>30</estimate>
          <role>DEV</role>
          <lines>1-3</lines>
        </puzzle>'
      ).xpath('/puzzle')
    )
    assert(not(github.updated?))
  end
  
  def test_adds_comment
    sources = Object.new
    def sources.config
      YAML.safe_load(
        "
tickets:
  - inherit-milestone
"
      )
    end
    github = FakeGithub.new
    def github.issue(_, _)
      { "milestone" => { "number" => 123, "title" => "v1.0" } }
    end
    def github.update_issue(_, _, options)
      # do nothing
    end
    def github.add_comment(repo, issue, text)
      @comment = text
    end
    class << github
      attr_accessor :comment
    end
    tickets = Object.new
    def tickets.submit(puzzle)
      { number: 123, href: 'http://0pdd.com' }
    end
    test = MilestoneTickets.new('yegor256/0pdd', sources, github, tickets)
    test.submit(
      Nokogiri::XML(
        '<puzzle>
          <id>23-ab536de</id>
          <file>/a/b/c/test.txt</file>
          <time>01-01-2017</time>
          <author>yegor</author>
          <body>привет дорогой друг, как твои дела?</body>
          <ticket>123</ticket>
          <estimate>30</estimate>
          <role>DEV</role>
          <lines>1-3</lines>
        </puzzle>'
      ).xpath('/puzzle')
    )
    assert(github.comment.starts_with?('This puzzle inherited milestone'))
  end
end

