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
  def initialize(repo, login, pwd, sources)
    @repo = repo
    @login = login
    @pwd = pwd
    @sources = sources
  end

  def submit(puzzle)
    # @todo #3:20min This mechanism of body abbreviation is rather
    #  primitive and doesn't produce readable texts very often. Instead
    #  of cutting the text at the hard limit (40 chars) we have to cut
    #  it at the end of the word, staying closer to the limit.
    title = puzzle.xpath('body').text.gsub(/^(.{40,}?).*$/m, '\1...')
    json = client.create_issue(
      @repo,
      "#{File.basename(puzzle.xpath('file').text)}:\
#{puzzle.xpath('lines').text}: #{title}",
      "The puzzle `#{puzzle.xpath('id').text}` \
in `#{puzzle.xpath('file').text}` (lines #{puzzle.xpath('lines').text}) \
has to be resolved: #{puzzle.xpath('body').text}\
\n\n\
The [puzzle](http://www.yegor256.com/2009/03/04/pdd.html) \
was created by #{puzzle.xpath('author').text} on \
#{Time.parse(puzzle.xpath('time').text).strftime('%d-%b-%y')}. \
\n\n\
Estimate: #{puzzle.xpath('estimate').text} minutes, \
role: #{puzzle.xpath('role').text}.\
\n\n\
If you have any technical questions, don't ask me, \
submit new tickets instead. The task will be \"done\" when \
the problem is fixed and the text of the puzzle is \
removed from the source code."
    )
    issue = json['number']
    unless users.empty?
      client.add_comment(
        @repo, issue,
        users.join(' ') + ' please pay attention to this new issue.'
      )
    end
    puts "GitHub issue #{@repo}:#{issue} submitted: #{users}"
    { number: issue, href: json['html_url'] }
  end

  def close(puzzle)
    issue = puzzle.xpath('issue').text
    client.close_issue(@repo, issue)
    client.add_comment(
      @repo,
      issue,
      "The puzzle `#{puzzle.xpath('id').text}` has disappeared from the \
source code, that's why I closed this issue." +
      (users.empty? ? '' : ' //cc ' + users.join(' '))
    )
    puts "GitHub issue #{@repo}:#{issue} closed: #{users}"
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

  def client
    if ENV['RACK_ENV'] == 'test'
      client = Object.new
      def client.close_issue(_, _)
        # nothing to do here
      end

      def client.add_comment(_, _, _)
        # nothing to do here
      end
      client
    else
      Octokit::Client.new(login: @login, password: @pwd)
    end
  end
end
