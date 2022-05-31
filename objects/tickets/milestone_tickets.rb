# Copyright (c) 2016-2022 Yegor Bugayenko
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
# Tickets that inherit milestones.
#
class MilestoneTickets
  def initialize(vcs, tickets)
    @vcs = vcs
    @tickets = tickets
  end

  def notify(issue, message)
    @tickets.notify(issue, message)
  end

  def submit(puzzle)
    submitted = @tickets.submit(puzzle)
    config = @vcs.repo.config
    if config['tickets']&.include?('inherit-milestone') &&
       puzzle.xpath('ticket')[0].text =~ /[0-9]+/
      num = puzzle.xpath('ticket')[0].text.to_i
      parent = @vcs.issue(num)
      unless parent.nil? || parent[:milestone].nil?
        begin
          @vcs.update_issue(
            num,
            milestone: parent[:milestone][:number]
          )
          unless config.dig('alerts', 'suppress')
            &.include?('on-inherited-milestone')
            @vcs.add_comment(
              submitted[:number],
              "This puzzle inherited milestone \
`#{parent[:milestone][:title]}` from issue ##{num}."
            )
          end
        rescue Octokit::Error, Gitlab::Error::Error => e
          @vcs.add_comment(
            submitted[:number],
            "For some reason I wasn't able to set milestone \
`#{parent[:milestone][:title]}`, inherited from `#{num}`, \
to this issue. Please, \
[submit a ticket](https://github.com/yegor256/0pdd/issues/new) \
to us with the text you see below:\
\n\n```#{e.class.name}\n#{e.message}\n#{e.backtrace.join("\n")}\n```"
          )
        end
      end
    end
    submitted
  end

  def close(puzzle)
    @tickets.close(puzzle)
  end
end
