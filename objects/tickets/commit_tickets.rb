# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

#
# Tickets that post into commits.
#
class CommitTickets
  def initialize(vcs, tickets)
    @vcs = vcs
    @commit = vcs.repo.head_commit_hash
    @tickets = tickets
  end

  def notify(issue, message)
    @tickets.notify(issue, message)
  end

  def submit(puzzle)
    done = @tickets.submit(puzzle)
    return done if suppressed_repo?

    @vcs.create_commit_comment(
      @commit,
      "Puzzle `#{puzzle.xpath('id')[0].text}` discovered in \
  [`#{puzzle.xpath('file')[0].text}`](#{@vcs.file_link(puzzle.xpath('file')[0].text)}) \
  and submitted as ##{done[:number]}. Please, remember that the puzzle was not \
  necessarily added in this particular commit. Maybe it was added earlier, but \
  we discovered it only now."
    )
    done
  end

  def close(puzzle)
    done = @tickets.close(puzzle)
    if done && !opts.include?('on-lost-puzzle')
      @vcs.create_commit_comment(
        @commit,
        "Puzzle `#{puzzle.xpath('id')[0].text}` disappeared from \
[`#{puzzle.xpath('file')[0].text}`](#{@vcs.file_link(puzzle.xpath('file')[0].text)}), \
that's why I closed ##{puzzle.xpath('issue')[0].text}. \
Please, remember that the puzzle was not necessarily removed in this \
particular commit. Maybe it happened earlier, but we discovered this fact \
only now."
      )
    end
    done
  end

  private

  def opts
    array = @vcs.repo.config.dig('alerts', 'suppress')
    array.nil? || !array.is_a?(Array) ? [] : array
  end

  def suppressed_repo?
    suppressed_options = %w[on-found-puzzle on-scope]
    suppressed_options.any? { |item| opts.include?(item) }
  end
end
