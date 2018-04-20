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

#
# Tickets that post into GitHub commits.
#
class CommitTickets
  def initialize(repo, sources, github, commit, tickets)
    @repo = repo
    @sources = sources
    @github = github
    @commit = commit
    @tickets = tickets
  end

  def notify(issue, message)
    @tickets.notify(issue, message)
  end

  def submit(puzzle)
    done = @tickets.submit(puzzle)
    unless @sources.config.dig('alerts', 'suppress', 'on-found-puzzle')
      @github.create_commit_comment(
        @repo, @commit,
        "Puzzle `#{puzzle.xpath('id')[0].text}` discovered in \
  [`#{puzzle.xpath('file')[0].text}`](\
  https://github.com/#{@repo}/blob/master/#{puzzle.xpath('file')[0].text}) \
  and submitted as ##{done[:number]}. Please, remember that the puzzle was not \
  necessarily added in this particular commit. Maybe it was added earlier, but \
  we discovered it only now."
      )
    end
    done
  end

  def close(puzzle)
    done = @tickets.close(puzzle)
    if done && !@sources.config.dig('alerts', 'suppress', 'on-lost-puzzle')
      @github.create_commit_comment(
        @repo, @commit,
        "Puzzle `#{puzzle.xpath('id')[0].text}` disappeared from \
[`#{puzzle.xpath('file')[0].text}`](\
https://github.com/#{@repo}/blob/master/#{puzzle.xpath('file')[0].text}), \
that's why I closed ##{puzzle.xpath('issue')[0].text}. \
Please, remember that the puzzle was not necessarily removed in this \
particular commit. Maybe it happened earlier, but we discovered this fact \
only now."
      )
    end
    done
  end
end
