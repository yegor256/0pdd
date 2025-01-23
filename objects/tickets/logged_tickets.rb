# Copyright (c) 2016-2025 Yegor Bugayenko
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

require 'cgi'
require_relative '../truncated'
require_relative '../user_error'

#
# Tickets that are logged.
#
class LoggedTickets
  def initialize(vcs, log, tickets)
    @vcs = vcs
    @log = log
    @tickets = tickets
  end

  def notify(issue, message)
    @tickets.notify(issue, message)
  end

  def submit(puzzle)
    tag = "#{puzzle.xpath('id')[0].text}/submit"
    if @log.exists(tag)
      raise UserError, "Tag \"#{tag}\" already exists, won't submit again. \
This situation most probably means that \
this puzzle was already seen in the code and \
you're trying to create it again. We would recommend you to re-phrase \
the text of the puzzle and push again. If this doesn't work, please let us know \
in GitHub: https://github.com/yegor256/0pdd/issues. More details here: \
http://www.0pdd.com/log-item?repo=#{CGI.escape(@vcs.repo.name)}&tag=#{CGI.escape(tag)}&vcs=#{@vcs.name.downcase} ."
    end
    done = @tickets.submit(puzzle)
    @log.put(
      tag,
      "#{puzzle.xpath('id')[0].text} submitted in issue ##{done[:number]}: \
\"#{Truncated.new(puzzle.xpath('body')[0].text, 100)}\" \
at #{puzzle.xpath('file')[0].text}; #{puzzle.xpath('lines')[0].text}"
    )
    done
  end

  def close(puzzle)
    done = @tickets.close(puzzle)
    if done
      tag = "#{puzzle.xpath('id')[0].text}/closed"
      if @log.exists(tag)
        raise UserError, "Tag \"#{tag}\" already exists, won't close again. \
This is a rare and rather unusual bug. Please report it to us: \
https://github.com/yegor256/0pdd/issues. More details here: \
http://www.0pdd.com/log-item?repo=#{CGI.escape(@vcs.repo.name)}&tag=#{CGI.escape(tag)}&vcs=#{@vcs.name.downcase} ."
      end
      @log.put(
        tag,
        "#{puzzle.xpath('id')[0].text} closed in issue \
##{puzzle.xpath('issue')[0].text}"
      )
    end
    done
  end
end
