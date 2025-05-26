# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'yaml'
require 'fake_github'
require_relative 'test__helper'
require_relative '../objects/tickets/milestone_tickets'

# MilestoneTickets test.
# Author:: George Aristy (george.aristy@gmail.com)
# Copyright:: Copyright (c) 2016-2025 Yegor Bugayenko
# License:: MIT
class TestGithubTickets < Minitest::Test
  def test_sets_milestone
    milestone = 123
    config = YAML.safe_load(
      "
tickets:
  - inherit-milestone
alerts:
  suppress:
    - on-inherited-milestone
    "
    )
    vcs = FakeGithub.new(repo: object(config: config))
    def vcs.issue(_)
      { milestone: { number: 123, title: 'v1.0' } }
    end

    def vcs.update_issue(_, options)
      @milestone = options[:milestone]
    end
    class << vcs
      attr_accessor :milestone
    end
    tickets = Object.new
    def tickets.submit(_)
      { number: 456, href: 'http://0pdd.com' }
    end
    test = MilestoneTickets.new(vcs, tickets)
    test.submit(
      Nokogiri::XML(
        '<puzzle>
          <id>23-ab536de</id>
          <file>/a/b/c/test.txt</file>
          <time>01-01-2019</time>
          <author>yegor</author>
          <body>привет дорогой друг, как твои дела?</body>
          <ticket>456</ticket>
          <estimate>30</estimate>
          <role>DEV</role>
          <lines>1-3</lines>
        </puzzle>'
      ).xpath('/puzzle')
    )
    assert_equal(milestone, vcs.milestone)
  end

  def test_does_not_set_milestone
    config = YAML.safe_load(
      '
alerts:
  suppress:
    - on-inherited-milestone
    '
    )
    vcs = FakeGithub.new(repo: object(config: config))
    def vcs.issue(_)
      { 'milestone' => { 'number' => 123, 'title' => 'v1.0' } }
    end

    def vcs.update_issue(_, _)
      @updated = true
    end
    class << vcs
      attr_accessor :updated
    end
    tickets = Object.new
    def tickets.submit(_)
      { number: 123, href: 'http://0pdd.com' }
    end
    test = MilestoneTickets.new(vcs, tickets)
    test.submit(
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
    refute(vcs.updated)
  end

  def test_adds_comment
    config = YAML.safe_load(
      '
tickets:
  - inherit-milestone
'
    )
    vcs = FakeGithub.new(repo: object(config: config))
    def vcs.issue(_)
      { milestone: { number: 123, title: 'v1.0' } }
    end

    def vcs.update_issue(_, _)
      # do nothing
    end

    def vcs.add_comment(_, text)
      @comment = text
    end
    class << vcs
      attr_accessor :comment
    end
    tickets = Object.new
    def tickets.submit(_)
      { number: 123, href: 'http://0pdd.com' }
    end
    test = MilestoneTickets.new(vcs, tickets)
    test.submit(
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
    assert(vcs.comment.start_with?('This puzzle inherited milestone'))
  end
end
