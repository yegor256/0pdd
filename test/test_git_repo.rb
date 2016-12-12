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
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'test/unit'
require 'tmpdir'
require_relative '../objects/git_repo'

# GitRepo test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016 Yegor Bugayenko
# License:: MIT
class TestGitRepo < Test::Unit::TestCase
  def test_clone_and_pull
    Dir.mktmpdir 'test' do |d|
      repo = GitRepo.new(name: 'teamed/pdd', dir: d, uri: git(d))
      repo.clone
      repo.pull
      assert(File.exist?(File.join(d, 'teamed/pdd/.git')))
    end
  end

  def test_push
    Dir.mktmpdir 'test' do |d|
      repo = GitRepo.new(name: 'teamed/est', dir: d, uri: git(d))
      repo.push
      repo.push
      assert(File.exist?(File.join(d, 'teamed/est/.git')))
    end
  end

  def test_fetch_puzzles
    Dir.mktmpdir 'test' do |d|
      repo = GitRepo.new(name: 'yegor256/0pdd', dir: d, uri: git(d))
      repo.push
      assert(!repo.xml.xpath('/puzzles').empty?)
    end
  end

  private

  def git(dir)
    raise unless system("
      set -e
      cd '#{dir}'
      git init repo
      cd repo
      git config user.email test@teamed.io
      git config user.name test
      echo 'hello, world!' > test.txt
      git add test.txt
      git commit -am 'add line'
    ")
    'file://' + File.join(dir, 'repo')
  end
end
