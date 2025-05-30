# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'haml'
require_relative '../truncated'
require_relative '../maybe_text'

#
# One ticket.
#
class Tickets
  def initialize(vcs)
    @vcs = vcs
  end

  def notify(issue, message)
    @vcs.add_comment(
      issue,
      "@#{@vcs.issue(issue)[:author][:username]} #{message}"
    )
  rescue Octokit::NotFound, Gitlab::NotFound, JIRA::NotFound => e
    puts "The issue most probably is not found, can't comment: #{e.message}"
  end

  def submit(puzzle)
    data = { title: title(puzzle), description: body(puzzle) }
    issue = @vcs.create_issue(data)
    unless users.empty?
      @vcs.add_comment(
        issue[:number],
        (users + ['please pay attention to this new issue.']).join(' ')
      )
    end
    { number: issue[:number], href: issue[:html_url] }
  end

  def close(puzzle)
    issue = puzzle.xpath('issue')[0].text
    return true if @vcs.issue(issue)[:state] == 'closed'
    @vcs.close_issue(issue)
    @vcs.add_comment(
      issue,
      [
        "The puzzle `#{puzzle.xpath('id')[0].text}` has disappeared",
        " from the source code, that's why I closed this issue.",
        (users.empty? ? '' : " //cc #{users.join(' ')}")
      ].join
    )
    true
  end

  private

  def users
    yaml = @vcs.repo.config
    if !yaml.nil? && yaml['alerts'] && yaml['alerts'][@vcs.name.downcase]
      yaml['alerts'][@vcs.name.downcase]
        .map { |x| x.strip.downcase }
        .map { |n| n.gsub(/[^0-9a-zA-Z-]+/, '') }
        .map { |n| n[0..64] }
        .map { |n| "@#{n}" }
    else
      []
    end
  end

  def title(puzzle)
    yaml = @vcs.repo.config
    format = []
    format += yaml['format'].map { |x| x.strip.downcase } if !yaml.nil? && yaml['format'].is_a?(Array)
    len = format.find { |i| i =~ /title-length=\d+/ }
    Truncated.new(
      if format.include?('short-title')
        puzzle.xpath('body')[0].text
      else
        subject = File.basename(puzzle.xpath('file')[0].text)
        start, stop = puzzle.xpath('lines')[0].text.split('-')
        [
          subject,
          ':',
          (start == stop ? start : "#{start}-#{stop}"),
          ": #{puzzle.xpath('body')[0].text}"
        ].join
      end,
      [[len ? len.gsub(/^title-length=/, '').to_i : 60, 30].max, 255].min
    ).to_s
  end

  def body(puzzle)
    file = puzzle.xpath('file')[0].text
    start, stop = puzzle.xpath('lines')[0].text.split('-')
    sha = @vcs.repo.head_commit_hash || vcs.repo.master
    url = @vcs.puzzle_link_for_commit(sha, file, start, stop)
    template = File.read(
      File.join(File.dirname(__FILE__), "../templates/#{@vcs.name.downcase}_tickets_body.haml")
    )
    Haml::Engine.new(template).render(
      Object.new, url: url, puzzle: puzzle
    )
  end
end
