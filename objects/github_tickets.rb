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
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'octokit'
require_relative 'truncated'

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
    if yaml['alerts'] && yaml['alerts']['github']
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
    if yaml['format'] && yaml['format'].is_a?(Array)
      format += yaml['format'].map(&:strip).map(&:downcase)
    end
    if format.include?('short-title')
      Truncated.new(puzzle.xpath('body')[0].text, 60)
    else
      subject = File.basename(puzzle.xpath('file')[0].text)
      lines = puzzle.xpath('lines')[0].text
      start, stop = lines.split('-')
      subject +
        ':' +
        (start == stop ? start : "#{start}-#{stop}") +
        ": #{Truncated.new(puzzle.xpath('body')[0].text)}"
    end
  end

  def body(puzzle)
    sha = @github.list_commits(@repo)[0]['sha']
    "The puzzle `#{puzzle.xpath('id')[0].text}` \
(from ##{puzzle.xpath('ticket')[0].text}) \
in [`#{puzzle.xpath('file')[0].text}`](\
https://github.com/#{@repo}/blob/#{sha}/#{puzzle.xpath('file')[0].text}) \
(lines #{puzzle.xpath('lines')[0].text}) \
has to be resolved: \"#{Truncated.new(puzzle.xpath('body')[0].text, 400)}\"\
\n\n\
The puzzle was created by #{puzzle.xpath('author')[0].text} on \
#{Time.parse(puzzle.xpath('time')[0].text).strftime('%d-%b-%y')}. \
\n\n\
Estimate: #{puzzle.xpath('estimate')[0].text} minutes, \
role: #{puzzle.xpath('role')[0].text}.\
\n\n\
If you have any technical questions, don't ask me, \
submit new tickets instead. The task will be \"done\" when \
the problem is fixed and the text of the puzzle is \
_removed_ from the source code. Here is more about \
[PDD](http://www.yegor256.com/2009/03/04/pdd.html) and \
[about me](http://www.yegor256.com/2017/04/05/pdd-in-action.html)."
  end
end
