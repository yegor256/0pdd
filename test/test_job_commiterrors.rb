# Copyright (c) 2016-2021 Yegor Bugayenko
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
require_relative 'test__helper'
require_relative '../objects/jobs/job_commiterrors'

# JobCommitErrors test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2021 Yegor Bugayenko
# License:: MIT
class TestJobCommitErrors < Test::Unit::TestCase
  class Stub
    attr_reader :reported
    def create_commit_comment(_, _, text)
      @reported = text
    end
  end

  def test_timeout_scenario
    job = Object.new
    def job.proceed
      raise 'Intended to be here'
    end
    github = Stub.new
    begin
      JobCommitErrors.new('yegor256/0pdd', github, '12345678', job).proceed
    rescue StandardError => e
      assert(!e.nil?)
    end
    assert(!github.reported.empty?)
  end
end
