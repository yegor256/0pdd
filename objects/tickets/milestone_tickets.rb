# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

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
        rescue Octokit::Error, Gitlab::Error::Error, JIRA::Error::Error => e
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
