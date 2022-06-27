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
require 'nokogiri'
require 'yaml'
require_relative 'test__helper'
require_relative '../objects/tickets/tickets'

# GithubTickets test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2022 Yegor Bugayenko
# License:: MIT
class TestGithubTickets < Test::Unit::TestCase
  def test_submits_tickets
    config = YAML.safe_load(
      "
alerts:
  github:
    - yegor256
    - davvd
format:
  - short-title
  - title-length=30
        "
    )
    repo = object(
      name: 'github',
      config: config,
      head_commit_hash: '123',
      master: 'master'
    )
    require_relative 'fake_github'
    vcs = FakeGithub.new(repo: repo)
    def vcs.create_issue(data)
      @data = data
      { number: 1, html_url: 'url' }
    end
    class << vcs
      attr_accessor :data
    end
    tickets = Tickets.new(vcs)
    tickets.submit(
      Nokogiri::XML(
        '<puzzle>
          <id>23-ab536de</id>
          <file>/a/b/c/test.txt</file>
          <time>01-01-2019</time>
          <author>yegor</author>
          <body>привет дорогой друг, как твои дела?</body>
          <ticket>123</ticket>
          <estimate>30</estimate>
          <role>DEV</role>
          <lines>1-3</lines>
        </puzzle>'
      ).xpath('/puzzle')
    )
    assert_equal('привет дорогой друг, как...', vcs.data[:title])
    assert(vcs.data[:description].start_with?('The puzzle `23-ab536de` from #123 has'))
  end

  def test_submits_tickets_log_title
    config = YAML.safe_load("\n\n")
    repo = object(
      name: 'github',
      config: config,
      head_commit_hash: '123',
      master: 'master'
    )
    require_relative 'fake_github'
    vcs = FakeGithub.new(repo: repo)
    def vcs.create_issue(data)
      @data = data
      { number: 1, html_url: 'url' }
    end
    class << vcs
      attr_accessor :data
    end
    tickets = Tickets.new(vcs)
    tickets.submit(
      Nokogiri::XML(
        '<puzzle>
          <id>55-ab536de</id>
          <file>/a/bz.txt</file>
          <time>01-05-2019</time>
          <author>yegor</author>
          <body>как дела? hey, how are you, please see this title!</body>
          <ticket>123</ticket>
          <estimate>30</estimate>
          <role>DEV</role>
          <lines>1-3</lines>
        </puzzle>'
      ).xpath('/puzzle')
    )
    assert_equal(
      'bz.txt:1-3: как дела? hey, how are you, please see this...',
      vcs.data[:title]
    )
    assert(vcs.data[:description].start_with?('The puzzle `55-ab536de` from #123 has'))
  end

  def test_output_estimates_when_it_is_not_zero
    config = YAML.safe_load("\n\n")
    repo = object(
      name: 'github',
      config: config,
      head_commit_hash: '123',
      master: 'master'
    )
    require_relative 'fake_github'
    vcs = FakeGithub.new(repo: repo)
    def vcs.create_issue(data)
      @data = data
      { number: 1, html_url: 'url' }
    end
    class << vcs
      attr_accessor :data
    end
    tickets = Tickets.new(vcs)
    tickets.submit(
      Nokogiri::XML(
        '<puzzle>
          <id>55-ab536de</id>
          <file>/a/bz.txt</file>
          <time>01-05-2019</time>
          <author>yegor</author>
          <body>как дела? hey, how are you, please see this title!</body>
          <ticket>123</ticket>
          <estimate>10</estimate>
          <role>DEV</role>
          <lines>1-3</lines>
        </puzzle>'
      ).xpath('/puzzle')
    )
    assert(vcs.data[:description].start_with?('The puzzle `55-ab536de` from #123 has'))
    assert(vcs.data[:description].include?('Estimate:'))
  end

  def test_skips_estimate_if_zero
    config = YAML.safe_load("\n\n")
    repo = object(
      name: 'github',
      config: config,
      head_commit_hash: '123',
      master: 'master'
    )
    require_relative 'fake_github'
    vcs = FakeGithub.new(repo: repo)
    def vcs.create_issue(data)
      @data = data
      { number: 1, html_url: 'url' }
    end
    class << vcs
      attr_accessor :data
    end
    tickets = Tickets.new(vcs)
    tickets.submit(
      Nokogiri::XML(
        '<puzzle>
          <id>55-ab536de</id>
          <file>/a/bz.txt</file>
          <time>01-05-2019</time>
          <author>yegor</author>
          <body>как дела? hey, how are you, please see this title!</body>
          <ticket>123</ticket>
          <estimate>0</estimate>
          <role>DEV</role>
          <lines>1-3</lines>
        </puzzle>'
      ).xpath('/puzzle')
    )
    assert(vcs.data[:description].start_with?('The puzzle `55-ab536de` from #123 has'))
    assert(!vcs.data[:description].include?('Estimate:'))
  end

  def test_closes_tickets
    config = YAML.safe_load("alerts:\n  github:\n    - yegor256\n    - davvd")
    repo = object(
      name: 'github',
      config: config,
      head_commit_hash: '123',
      master: 'master'
    )
    require_relative 'fake_github'
    tickets = Tickets.new(FakeGithub.new(repo: repo))
    tickets.close(
      Nokogiri::XML(
        '<puzzle><id>xx</id><issue>1</issue></puzzle>'
      ).xpath('/puzzle')
    )
  end
end
