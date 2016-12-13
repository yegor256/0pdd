# encoding: utf-8
#
# Copyright (c) 2016 Yegor Bugayenko
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

require 'timeout'
require_relative 'config'
require_relative 'git_repo'
require_relative 'github_tickets'
require_relative 'puzzles'
require_relative 'safe_storage'
require_relative 's3'

#
# One job.
#
class Job
  def initialize(name, sha)
    @name = name
    @sha = sha
  end

  def proceed
    Process.detach(
      fork do
        exclusive
      end
    )
  end

  private

  def safe
    f = File.open("/tmp/0lck/#{@name}.txt", File::RDWR | File::CREAT, 0o644)
    Timeout.timeout(10) do
      f.flock(File::LOCK_EX)
      sleep(5.seconds) # to make sure Git repo is up to date
      run
      f.close
    end
  end

  def run
    cfg = Config.new.yaml
    repo = GitRepo.new(name: name, id_rsa: cfg['id_rsa'])
    repo.push(@sha)
    puzzles = Puzzles.new(
      repo,
      SafeStorage.new(
        S3.new(
          "#{name}.xml",
          cfg['s3']['bucket'],
          cfg['s3']['region'],
          cfg['s3']['key'],
          cfg['s3']['secret']
        )
      )
    )
    puzzles.deploy(
      GithubTickets.new(
        name,
        cfg['github']['login'],
        cfg['github']['pwd']
      )
    )
  end
end
