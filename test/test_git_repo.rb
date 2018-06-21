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
require 'tmpdir'
require_relative 'test__helper'
require_relative '../objects/git_repo'
require_relative '../objects/user_error'

# GitRepo test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2018 Yegor Bugayenko
# License:: MIT
class TestGitRepo < Test::Unit::TestCase
  def test_clone_and_pull
    Dir.mktmpdir 'test' do |d|
      repo = GitRepo.new(name: 'yegor256/pdd', dir: d, uri: git(d))
      repo.push
      repo.push
      assert(File.exist?(File.join(d, 'yegor256/pdd/.git')))
    end
  end

  def test_merge_unrelated_histories
    Dir.mktmpdir 'test' do |d|
      dir = 'repo'
      repo = GitRepo.new(name: 'yegor256/pdd', dir: d, uri: git(d, dir))
      repo.push
      Exec.new("
        set -e
        cd '#{d}/#{dir}'
        git checkout -b temp
        git branch -D master
        git checkout --orphan master
        echo 'hello, dude!' > new.txt
        git add new.txt
        git commit --quiet -am 'new master'
      ").run
      repo.push
      assert(File.exist?(File.join(d, 'yegor256/pdd/new.txt')))
    end
  end

  def test_fail_with_user_error
    Dir.mktmpdir 'test' do |d|
      dir = 'repo'
      repo = GitRepo.new(name: 'yegor256/pdd', dir: d, uri: git(d, dir))
      repo.push
      Exec.new("
        set -e
        cd '#{d}/#{dir}'
        echo '...\x40todoBad puzzle' > z1.txt
        echo '\x40todo #1 Good puzzle' > z2.txt
        git add z1.txt z2.txt
        git commit --quiet --amend --message 'zz'
      ").run
      repo.push
      assert_raises UserError do
        repo.xml
      end
    end
  end

  def test_merge_after_ammend
    Dir.mktmpdir 'test' do |d|
      dir = 'repo'
      repo = GitRepo.new(name: 'yegor256/pdd', dir: d, uri: git(d, dir))
      repo.push
      Exec.new("
        set -e
        cd '#{d}/#{dir}'
        echo 'hello, dude!' > z.txt
        git add z.txt
        git commit --quiet --amend --message 'new fix'
      ").run
      repo.push
      assert(File.exist?(File.join(d, 'yegor256/pdd/z.txt')))
    end
  end

  def test_merge_after_force_push
    Dir.mktmpdir 'test' do |d|
      dir = 'repo'
      repo = GitRepo.new(name: 'yegor256/pdd', dir: d, uri: git(d, dir))
      repo.push
      Exec.new("
        set -e
        cd '#{d}/#{dir}'
        git reset HEAD~2
        git reset --hard
        git clean -fd
        echo 'hello, dude!' >> z.txt && git add z.txt && git commit -m ddd
        echo 'hello, dude!' >> z.txt && git add z.txt && git commit -m ddd
        echo 'hello, dude!' >> z.txt && git add z.txt && git commit -m ddd
      ").run
      repo.push
      assert(File.exist?(File.join(d, 'yegor256/pdd/z.txt')))
    end
  end

  def test_merge_after_complete_new_master
    Dir.mktmpdir 'test' do |d|
      dir = 'repo'
      repo = GitRepo.new(name: 'yegor256/pdd', dir: d, uri: git(d, dir))
      repo.push
      Exec.new("
        set -e
        cd '#{d}/#{dir}'
        git checkout -b temp
        git branch -D master
        git checkout --orphan master
        echo 'hello, new!' >> z.txt && git add z.txt && git commit -m ddd
        echo 'hello, new!' >> z.txt && git add z.txt && git commit -m ddd
        echo 'hello, new!' >> z2.txt && git add z2.txt && git commit -m ddd
      ").run
      repo.push
      assert(File.exist?(File.join(d, 'yegor256/pdd/z.txt')))
      assert(File.exist?(File.join(d, 'yegor256/pdd/z2.txt')))
    end
  end

  def test_doesnt_touch_crlf
    omit
    # I can't reproduce the problem of #125. The code works as it should
    # be, however in production it fails due to some issues with CRLF
    # in binary files.
    # See also: https://stackoverflow.com/questions/46539254
    Dir.mktmpdir 'test' do |d|
      dir = 'repo'
      repo = GitRepo.new(name: 'yegor256/pdd', dir: d, uri: git(d, dir))
      Exec.new("
        set -e
        cd '#{d}/#{dir}'
        git config --local core.autocrlf false
        echo -n -e 'Hello, world!\r\nHow are you?' >> crlf.txt \
          && git add . && git commit -am crlf.txt
      ").run
      repo.push
      assert_equal(
        File.read(File.join(d, 'yegor256/pdd/crlf.txt')),
        "Hello, world!\n\rHow are you?"
      )
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

  def test_fetch_config
    clean_dir = ""
    begin
      Dir.mktmpdir 'test' do |d|
        clean_dir = d
        repo = GitRepo.new(name: 'yegor256/0pdd', dir: d, uri: git(d))
        repo.push
        assert(repo.config['foo'])
      end
    # HACK: (For Win) Don't deal with deletion issues
    # Data stored in temp dir, system can deal with it by itself.
    # On Linux: /tmp gets wiped on reboot automatically
    # On Windows: %temp% gets wiped as needed (Win10 Storage Sense)
    rescue Errno::ENOTEMPTY
      FileUtils.remove_entry(clean_dir, true)
    end
  end

  private

  def git(dir, subdir = 'repo')
    Exec.new("
      set -e
      cd '#{dir}'
      git init --quiet #{subdir}
      cd #{subdir}
      git config user.email git@0pdd.com
      git config user.name 0pdd
      echo 'foo: hello' > .0pdd.yml
      git add .0pdd.yml
      git commit --quiet -am 'add line'
      echo 'hello, world!' >> z.txt && git add z.txt && git commit -am z
      echo 'hello, world!' >> z.txt && git add z.txt && git commit -am z
      echo 'hello, world!' >> z.txt && git add z.txt && git commit -am z
      echo 'hello, world!' >> z.txt && git add z.txt && git commit -am z
      echo 'hello, world!' >> z.txt && git add z.txt && git commit -am z
    ").run
    'file://' + File.join(dir, subdir)
  end
end
