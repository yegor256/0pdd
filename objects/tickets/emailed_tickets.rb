# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

#
# Tickets that email when submitted or closed.
#
class EmailedTickets
  def initialize(vcs, tickets)
    @vcs = vcs
    @tickets = tickets
  end

  def notify(issue, message)
    @tickets.notify(issue, message)
  end

  def submit(puzzle)
    done = @tickets.submit(puzzle)
    issue_link = @vcs.issue_link(done[:number])
    file_link = @vcs.file_link(puzzle.xpath('file')[0].text)
    Mail.new do
      from '0pdd <no-reply@0pdd.com>'
      to 'admin@0pdd.com'
      subject "#{issue_link} opened"
      text_part do
        content_type 'text/plain; charset=UTF-8'
        body "Hey,\n\n\
Issue #{done[:href]} opened.\n\n\
ID: #{puzzle.xpath('id')[0].text}\n\
File: #{puzzle.xpath('file')[0].text}\n\
Lines: #{puzzle.xpath('lines')[0].text}\n\
Here: #{file_link}\
##{puzzle.xpath('lines')[0].text.gsub(/(\d+)/, 'L\1')}\n\
Author: #{puzzle.xpath('author')[0].text}\n\
Time: #{puzzle.xpath('time')[0].text}\n\
Estimate: #{puzzle.xpath('estimate')[0].text} minutes\n\
Role: #{puzzle.xpath('role')[0].text}\n\n\
Body: #{puzzle.xpath('body')[0].text}\n\n\
Thanks,\n\
0pdd"
      end
    end.deliver!
    done
  end

  def close(puzzle)
    done = @tickets.close(puzzle)
    if done
      issue_number = puzzle.xpath('issue')[0].text
      issue_link = @vcs.issue_link(issue_number)
      Mail.new do
        from '0pdd <no-reply@0pdd.com>'
        to 'admin@0pdd.com'
        subject "#{issue_link} closed"
        text_part do
          content_type 'text/plain; charset=UTF-8'
          body "Hey,\n\n\
Issue #{issue_link} closed.\n\n\
Thanks,\n\
0pdd"
        end
      end.deliver!
    end
    done
  end
end
