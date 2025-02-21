# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

#
# Job that stars the repo.
# API: http://octokit.github.io/octokit.rb/method_list.html
#
class JobStarred
  def initialize(vcs, job)
    @vcs = vcs
    @job = job
  end

  def proceed
    output = @job.proceed
    @vcs.star
    output
  end
end
