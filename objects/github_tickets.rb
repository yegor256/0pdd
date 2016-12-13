# encoding: utf-8
#
# Copyright (c) 2016 Yegor Bugayenko
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

#
# Tickets in Github
#
class GithubTickets
  def initialize(repo, login, pwd)
    @repo = repo
    @login = login
    @pwd = pwd
  end

  def submit(puzzle)
    ticket = client.create_issue(
      @repo,
      "#{File.basename(puzzle.xpath('file').text)}:\
#{puzzle.xpath('lines').text}: \
#{puzzle.xpath('body').text.gsub(/^(.{40,}?).*$/m, '\1...')}",
      "The puzzle `#{puzzle.xpath('id').text}` \
in `#{puzzle.xpath('file').text}` (lines #{puzzle.xpath('lines').text}) \
has to be resolved: #{puzzle.xpath('body').text}. \
The puzzle was created by #{puzzle.xpath('author').text} on \
#{Time.parse(puzzle.xpath('time').text).strftime('%d-%b-%y')}. \
\n\n\
Estimate: #{puzzle.xpath('estimate').text} minutes, \
Role: #{puzzle.xpath('role').text}.\
\n\n\
If you have any technical questions, don't ask me, \
submit new tickets instead. The task will be \"done\" when \
the problem is fixed and the text of the puzzle is \
removed from the source code."
    )['number']
    puts "GitHub issue #{@repo}:#{ticket} submitted"
    ticket
  end

  def close(puzzle)
    issue = puzzle.xpath('issue').text
    client.close_issue(@repo, issue)
    client.add_comment(
      @repo, issue,
      "The puzzle #{puzzle.xpath('id').text} has disappeared from the \
source code, that's why I closed this issue."
    )
    puts "GitHub issue #{@repo}:#{issue} closed"
  end

  private

  def client
    Octokit::Client.new(login: @login, password: @pwd)
  end
end
