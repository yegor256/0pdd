# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'yaml'
require_relative 'test__helper'
require_relative '../objects/tickets/tickets'

# GithubTickets test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2025 Yegor Bugayenko
# License:: MIT
class TestGithubTickets < Minitest::Test
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
    assert_includes(vcs.data[:description], 'Estimate:')
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
    refute_includes(vcs.data[:description], 'Estimate:')
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
