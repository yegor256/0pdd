# Copyright (c) 2016-2020 Yegor Bugayenko
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
require_relative 'fake_repo'
require_relative 'fake_github'
require_relative '../objects/job_emailed'

# JobEmailed test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2020 Yegor Bugayenko
# License:: MIT
class TestJobEmailed < Test::Unit::TestCase
  def fake_job
    job = stub
    job.stubs(:proceed)
    job
  end

  def test_simple_scenario
    repo = FakeRepo.new
    github = FakeGithub.new
    job = fake_job
    JobEmailed.new('yegor256/0pdd', github, repo, job).proceed
  end

  def test_exception_mail_to_repo_owner_as_cc
    exception_class = Exception
    repo = FakeRepo.new
    github = FakeGithub.new
    job = fake_job
    job.expects(:proceed).raises(exception_class)
    Mail::Message.any_instance.stubs(:deliver!)
    Mail::Message.any_instance.expects(:cc=).with('foobar@example.com')
    assert_raise Exception do
      JobEmailed.new('yegor256/0pdd', github, repo, job).proceed
    end
  end
end
