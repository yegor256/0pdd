# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'fileutils'

#
# One job.
#
class JobDetached
  def initialize(vcs, job)
    @vcs = vcs
    @job = job
  end

  def proceed
    if ENV['RACK_ENV'] == 'test'
      exclusive
    else
      Process.detach(fork { exclusive })
    end
  end

  private

  def exclusive
    lock = @vcs.repo.lock
    FileUtils.mkdir_p(File.dirname(lock))
    f = File.open(lock, File::RDWR | File::CREAT, 0o644)
    f.flock(File::LOCK_EX)
    begin
      @job.proceed
    ensure
      f.close
      begin
        File.delete(lock)
      rescue Errno::EACCES
        lock.close
        File.delete(lock)
      end
    end
  end
end
