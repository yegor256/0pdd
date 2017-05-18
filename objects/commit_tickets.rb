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

#
# Tickets that post into GitHub commits.
#
class CommitTickets
  def initialize(repo, github, commit, tickets)
    @repo = repo
    @github = github
    @commit = commit
    @tickets = tickets
  end

  def safe
    @tickets.safe
  end

  def submit(puzzle)
    done = @tickets.submit(puzzle)
    @github.create_commit_comment(
      @repo, @commit,
      "Puzzle `#{puzzle.xpath('id').text}` discovered in \
[`#{puzzle.xpath('file').text}`](\
https://github.com/#{@repo}/blob/master/#{puzzle.xpath('file').text}) \
and submitted as ##{done[:number]}."
    )
    done
  end

  def close(puzzle)
    done = @tickets.close(puzzle)
    if done
      @github.create_commit_comment(
        @repo, @commit,
        "Puzzle `#{puzzle.xpath('id').text}` disappeared in \
[`#{puzzle.xpath('file').text}`](\
https://github.com/#{@repo}/blob/master/#{puzzle.xpath('file').text}), \
that's why I closed ##{puzzle.xpath('issue').text}."
      )
    end
    done
  end
end
