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

  # Is it safe to do something right now or it's better to wait a bit?
  def safe
    @github.rate_limit.remaining > 2000
  end

  def submit(puzzle)
    json = @github.create_issue(
      @repo,
      "#{File.basename(puzzle.xpath('file').text)}:\
#{puzzle.xpath('lines').text}: #{Truncated.new(puzzle.xpath('body').text)}",
      "The puzzle `#{puzzle.xpath('id').text}` \
(from ##{puzzle.xpath('ticket').text}) \
in [`#{puzzle.xpath('file').text}`](\
https://github.com/#{@repo}/blob/master/#{puzzle.xpath('file').text}) \
(lines #{puzzle.xpath('lines').text}) \
has to be resolved: \"#{Truncated.new(puzzle.xpath('body').text, 400)}\"\
\n\n\
The puzzle was created by #{puzzle.xpath('author').text} on \
#{Time.parse(puzzle.xpath('time').text).strftime('%d-%b-%y')}. \
\n\n\
Estimate: #{puzzle.xpath('estimate').text} minutes, \
role: #{puzzle.xpath('role').text}.\
\n\n\
If you have any technical questions, don't ask me, \
submit new tickets instead. The task will be \"done\" when \
the problem is fixed and the text of the puzzle is \
_removed_ from the source code. Here is more about \
[PDD](http://www.yegor256.com/2009/03/04/pdd.html) and \
[about me](http://www.yegor256.com/2017/04/05/pdd-in-action.html)."
    )
    issue = json['number']
    unless users.empty?
      @github.add_comment(
        @repo, issue,
        users.join(' ') + ' please pay attention to this new issue.'
      )
    end
    puts "GitHub issue #{@repo}##{issue} submitted: #{users}"
    { number: issue, href: json['html_url'] }
  end

  def close(puzzle)
    issue = puzzle.xpath('issue').text
    return false if @github.issue(@repo, issue)['state'] == 'closed'
    @github.close_issue(@repo, issue)
    @github.add_comment(
      @repo,
      issue,
      "The puzzle `#{puzzle.xpath('id').text}` has disappeared from the \
source code, that's why I closed this issue." +
      (users.empty? ? '' : ' //cc ' + users.join(' '))
    )
    puts "GitHub issue #{@repo}:#{issue} closed: #{users}"
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
end
