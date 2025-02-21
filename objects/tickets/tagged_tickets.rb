# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

#
# Tagged tickets.
#
class TaggedTickets
  def initialize(vcs, tickets)
    @vcs = vcs
    @tickets = tickets
  end

  def notify(issue, message)
    @tickets.notify(issue, message)
  end

  def submit(puzzle)
    issue = @tickets.submit(puzzle)
    issue_id = issue[:number]
    yaml = @vcs.repo.config
    if yaml['tags'].is_a?(Array)
      tags = yaml['tags'].map(&:strip).map(&:downcase)
      labels = @vcs.labels
        .map { |json| json[:name] }
        .map(&:strip).map(&:downcase)
      needed = tags - labels
      begin
        needed.each { |t| @vcs.add_label(t, 'F74219') }
        @vcs.add_labels_to_an_issue(issue_id, tags)
      rescue Octokit::Error, Gitlab::Error::Error, JIRA::Error::Error => e
        @vcs.add_comment(
          issue_id,
          "I can't create #{@vcs.name} labels `#{needed.join('`, `')}`. \
Most likely I don't have necessary permissions to `#{@vcs.repo.name}` repository. \
Please, make sure @0pdd user is in the \
[list of collaborators](#{@vcs.collaborators_link}):\
\n\n```#{e.class.name}\n#{e.message}\n#{e.backtrace.join("\n")}\n```"
        )
      rescue Octokit::NotFound, Gitlab::Error::NotFound, JIRA::Error::NotFound => e
        @vcs.add_comment(
          issue_id,
          "For some reason I wasn't able to add #{@vcs.name} labels \
`#{needed.join('`, `')}` to this issue \
(required=`#{tags.join('`, `')}`; existing=`#{labels.join('`, `')}`). \
Please, [submit a ticket](https://github.com/yegor256/0pdd/issues/new) \
to us with the text you see below:\
\n\n```#{e.class.name}\n#{e.message}\n#{e.backtrace.join("\n")}\n```"
        )
      end
    end
    issue
  end

  def close(puzzle)
    @tickets.close(puzzle)
  end
end
