# Copyright (c) 2016-2018 Yegor Bugayenko
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
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'test/unit'
require 'mocha/test_unit'
require 'timeout'
require_relative 'test__helper'
require_relative 'fake_repo'
require_relative 'fake_github'
require_relative '../objects/job_commiterrors'

# JobCommitErrors test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2018 Yegor Bugayenko
# License:: MIT
class TestJobCommitErrors < Test::Unit::TestCase
  def test_timeout_scenario
    repo = FakeRepo.new
    job = Object.new
    def job.proceed
      sleep(100)
    end
    reported = []
    github = Object.new
    def github.create_commit_comment(name, commit, text)
      reported << text
    end
    begin
      Timeout.timeout(1) do
        JobCommitErrors.new('yegor256/0pdd', github, '12345678', job).proceed
      end
    rescue Timeout::Error
      # ignore it
    end
    assert_equal(1, reported.count)
  end
end
