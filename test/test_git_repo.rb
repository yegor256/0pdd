# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'tmpdir'
require_relative 'test__helper'
require_relative '../objects/git_repo'
require_relative '../objects/user_error'

# GitRepo test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2025 Yegor Bugayenko
# License:: MIT
class TestGitRepo < Minitest::Test
  def test_clone_and_pull
    Dir.mktmpdir 'test' do |d|
      _, uri = git(d)
      repo = GitRepo.new(name: 'yegor256/pdd', dir: d, uri: uri)
      repo.push
      repo.push
      assert_path_exists(File.join(repo.path, '.git'))
    end
  end

  def test_merge_unrelated_histories
    Dir.mktmpdir 'test' do |d|
      path, uri = git(d, 'repo')
      repo = GitRepo.new(name: 'yegor256/pdd', dir: d, uri: uri)
      repo.push
      qbash("
        set -e
        cd '#{Shellwords.escape(path)}'
        git checkout -b temp
        git branch -D master
        git checkout --orphan master
        echo 'hello, dude!' > new.txt
        git add new.txt
        git commit --no-verify --quiet -am 'new master'
      ")
      repo.push
      assert_path_exists(File.join(repo.path, 'new.txt'))
    end
  end

  def test_fail_with_user_error
    Dir.mktmpdir 'test' do |d|
      path, uri = git(d, 'repo')
      repo = GitRepo.new(name: 'yegor256/pdd', dir: d, uri: uri)
      repo.push
      qbash(
        "
        set -e
        cd '#{Shellwords.escape(path)}'
        echo '...\x40todoBad puzzle' > z1.txt
        echo '\x40todo #1 Good puzzle' > z2.txt
        git add z1.txt z2.txt
        git commit --no-verify --quiet --amend --message 'zz'
        "
      )
      repo.push
      assert_raises(UserError) do
        repo.xml
      end
    end
  end

  def test_merge_after_amend
    Dir.mktmpdir 'test' do |d|
      path, uri = git(d, 'repo')
      repo = GitRepo.new(name: 'yegor256/pdd', dir: d, uri: uri)
      repo.push
      qbash("
        set -e
        cd '#{Shellwords.escape(path)}'
        echo 'hello, dude!' > z.txt
        git add z.txt
        git commit --no-verify --quiet --amend --message 'new fix'
      ")
      repo.push
      assert_path_exists(File.join(repo.path, 'z.txt'))
    end
  end

  def test_merge_after_force_push
    Dir.mktmpdir 'test' do |d|
      path, uri = git(d, 'repo')
      repo = GitRepo.new(name: 'yegor256/pdd', dir: d, uri: uri)
      repo.push
      qbash("
        set -e
        cd '#{Shellwords.escape(path)}'
        git reset HEAD~2
        git reset --hard
        git clean -fd
        echo 'hello, dude!' >> z.txt && git add z.txt && git commit --no-verify -m ddd
        echo 'hello, dude!' >> z.txt && git add z.txt && git commit --no-verify -m ddd
        echo 'hello, dude!' >> z.txt && git add z.txt && git commit --no-verify -m ddd
      ")
      repo.push
      assert_path_exists(File.join(repo.path, 'z.txt'))
    end
  end

  def test_merge_after_complete_new_master
    Dir.mktmpdir 'test' do |d|
      path, uri = git(d, 'repo')
      repo = GitRepo.new(name: 'yegor256/pdd', dir: d, uri: uri)
      repo.push
      qbash("
        set -e
        cd '#{Shellwords.escape(path)}'
        git checkout -b temp
        git branch -D master
        git checkout --orphan master
        echo 'hello, new!' >> z.txt && git add z.txt && git commit --no-verify -m ddd
        echo 'hello, new!' >> z.txt && git add z.txt && git commit --no-verify -m ddd
        echo 'hello, new!' >> z2.txt && git add z2.txt && git commit --no-verify -m ddd
      ")
      repo.push
      assert_path_exists(File.join(repo.path, 'z.txt'))
      assert_path_exists(File.join(repo.path, 'z2.txt'))
    end
  end

  def test_doesnt_touch_crlf
    skip('...')
    # I can't reproduce the problem of #125. The code works as it should
    # be, however in production it fails due to some issues with CRLF
    # in binary files.
    # See also: https://stackoverflow.com/questions/46539254
    Dir.mktmpdir 'test' do |d|
      path, uri = git(d, 'repo')
      repo = GitRepo.new(name: 'yegor256/pdd', dir: d, uri: uri)
      qbash("
        set -e
        cd '#{Shellwords.escape(path)}'
        git config --local core.autocrlf false
        echo -n -e 'Hello, world!\r\nHow are you?' >> crlf.txt \
          && git add . && git commit --no-verify -am crlf.txt
      ")
      repo.push
      assert_equal(
        "Hello, world!\n\rHow are you?",
        File.read(File.join(repo.path, 'crlf.txt'))
      )
    end
  end

  def test_push
    Dir.mktmpdir 'test' do |d|
      _, uri = git(d)
      repo = GitRepo.new(name: 'teamed/est', dir: d, uri: uri)
      repo.push
      repo.push
      assert_path_exists(File.join(repo.path, '.git'))
    end
  end

  def test_fetch_puzzles
    Dir.mktmpdir 'test' do |d|
      _, uri = git(d)
      repo = GitRepo.new(name: 'yegor256/0pdd', dir: d, uri: uri)
      repo.push
      refute_empty(repo.xml.xpath('/puzzles'))
    end
  end

  def test_fetch_config
    clean_dir = ''
    begin
      Dir.mktmpdir 'test' do |d|
        clean_dir = d
        _, uri = git(d)
        repo = GitRepo.new(name: 'yegor256/0pdd', dir: d, uri: uri)
        repo.push
        assert(repo.config['foo'])
      end
    rescue Errno::ENOTEMPTY
      FileUtils.remove_entry(clean_dir, true)
    end
  end

  private

  def git(dir, subdir = 'repo')
    qbash("
      set -e
      cd '#{Shellwords.escape(dir)}'
      git init --quiet #{Shellwords.escape(subdir)}
      cd #{Shellwords.escape(subdir)}
      git config user.email git@0pdd.com
      git config user.name 0pdd
      echo 'foo: hello' > .0pdd.yml
      git add .0pdd.yml
      git commit --no-verify --quiet -am 'add line'
      echo 'hello, world!' >> z.txt && git add z.txt && git commit --no-verify -am z
      echo 'hello, world!' >> z.txt && git add z.txt && git commit --no-verify -am z
      echo 'hello, world!' >> z.txt && git add z.txt && git commit --no-verify -am z
      echo 'hello, world!' >> z.txt && git add z.txt && git commit --no-verify -am z
      echo 'hello, world!' >> z.txt && git add z.txt && git commit --no-verify -am z
    ")
    path = File.join(dir, subdir)
    [path, "file://#{path}"]
  end
end
