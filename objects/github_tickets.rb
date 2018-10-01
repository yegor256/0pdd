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
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'haml'
require 'octokit'
require_relative 'truncated'
require_relative 'maybe_text'

#
# Tickets in Github.
# API: http://octokit.github.io/octokit.rb/method_list.html
#
class GithubTickets
  def initialize(repo, github, sources)
    @repo = repo
    @github = github
    @sources = sources
  end

  def notify(issue, message)
    @github.add_comment(
      @repo, issue,
      "@#{@github.issue(@repo, issue)['user']['login']} #{message}"
    )
  end

  def submit(puzzle)
    json = @github.create_issue(
      @repo,
      title(puzzle),
      body(puzzle)
    )
    issue = json['number']
    unless users.empty?
      @github.add_comment(
        @repo, issue,
        users.join(' ') + ' please pay attention to this new issue.'
      )
    end
    { number: issue, href: json['html_url'] }
  end

  def close(puzzle)
    issue = puzzle.xpath('issue')[0].text
    return true if @github.issue(@repo, issue)['state'] == 'closed'
    @github.close_issue(@repo, issue)
    @github.add_comment(
      @repo,
      issue,
      "The puzzle `#{puzzle.xpath('id')[0].text}` has disappeared from the \
source code, that's why I closed this issue." +
      (users.empty? ? '' : ' //cc ' + users.join(' '))
    )
    true
  end

  private

  def users
    yaml = @sources.config
    if !yaml.nil? && yaml['alerts'] && yaml['alerts']['github']
      yaml['alerts']['github']
        .map(&:strip)
        .map(&:downcase)
        .map { |n| n.gsub(/[^0-9a-zA-Z-]+/, '') }
        .map { |n| n[0..64] }
        .map { |n| "@#{n}" }
    else
      []
    end
  end

  def title(puzzle)
    yaml = @sources.config
    format = []
    format += yaml['format'].map(&:strip).map(&:downcase) if !yaml.nil? && yaml['format'].is_a?(Array)
    len = format.find { |i| i =~ /title-length=\d+/ }
    Truncated.new(
      if format.include?('short-title')
        puzzle.xpath('body')[0].text
      else
        subject = File.basename(puzzle.xpath('file')[0].text)
        start, stop = puzzle.xpath('lines')[0].text.split('-')
        subject +
          ':' +
          (start == stop ? start : "#{start}-#{stop}") +
          ": #{puzzle.xpath('body')[0].text}"
      end,
      [[len ? len.gsub(/^title-length=/, '').to_i : 60, 30].max, 255].min
    ).to_s
  end

  def body(puzzle)
    file = puzzle.xpath('file')[0].text
    start, stop = puzzle.xpath('lines')[0].text.split('-')
    sha = @github.list_commits(@repo)[0]['sha']
    url = "https://github.com/#{@repo}/blob/#{sha}/#{file}#L#{start}-L#{stop}"
    template = File.read(
      File.join(File.dirname(__FILE__), 'templates/github_tickets_body.haml')
    )
    Haml::Engine.new(template).render(
      Object.new, url: url, puzzle: puzzle
    )
  end
end
