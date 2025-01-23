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
