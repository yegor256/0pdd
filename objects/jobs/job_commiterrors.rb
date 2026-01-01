# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../truncated'

#
# Job that posts exceptions as commit messages.
#
class JobCommitErrors
  def initialize(vcs, job)
    @vcs = vcs
    @job = job
  end

  def proceed
    @job.proceed
  rescue Exception => e
    done = @vcs.create_commit_comment(
      @vcs.repo.head_commit_hash,
      "I wasn't able to retrieve PDD puzzles from the code base and \
submit them to #{@vcs.name}. If you \
think that it's a bug on our side, please submit it to \
[yegor256/0pdd](https://github.com/yegor256/0pdd/issues):\n\n\
> #{Truncated.new(e.message.gsub(/\s/, ' '), 300)}\n\n
Please, copy and paste this stack trace to GitHub:\n\n
```\n#{e.class.name}\n#{e.message}\n#{e.backtrace.join("\n")}\n```"
    )
    puts "Comment posted about an error: #{done[:html_url]}"
    raise e
  end
end
