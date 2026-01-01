# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

#
# Job that records all requests.
#
class JobRecorded
  def initialize(vcs, job)
    @vcs = vcs
    @job = job
  end

  def proceed
    @job.proceed
    open('/tmp/0pdd-done.txt', 'a+') do |f|
      f.puts(@vcs.repo.name)
    end
  end
end
