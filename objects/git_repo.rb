# encoding: utf-8
#
# Copyright (c) 2016-2017 Yegor Bugayenko
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
require 'pdd'
require 'tempfile'
require 'yaml'
require_relative 'exec'

#
# Repository in Git
#
class GitRepo
  def initialize(
    name:, dir: '/tmp/0pdd',
    uri: "git@github.com:#{name}", id_rsa: ''
  )
    @name = name
    @path = "#{dir}/#{@name}"
    @uri = uri
    @id_rsa = id_rsa
  end

  def lock
    "/tmp/0pdd-locks/#{@name}.txt"
  end

  def config
    f = File.join(@path, '.0pdd.yml')
    if File.exist?(f)
      puts "#{File.basename(f)} found at #{@name}: #{File.size(f)} bytes"
      YAML.load(File.open(f))
    else
      {}
    end
  end

  def xml
    tmp = Tempfile.new('pdd.xml')
    raise "Path is absent: #{@path}" unless File.exist?(@path)
    Exec.new("cd #{@path} && pdd -q -f #{tmp.path}").run
    Nokogiri::XML(File.open(tmp))
  end

  def push
    if File.exist?(@path)
      pull
    else
      clone
    end
  end

  def clone
    prepare_key
    prepare_git
    Exec.new(
      'git clone',
      '--depth=1',
      @uri,
      @path,
      '--quiet'
    ).run
  end

  def pull
    prepare_key
    prepare_git
    Exec.new(
      [
        "cd #{@path}",
        'git reset --hard --quiet',
        'git clean --force -d',
        'git fetch --quiet',
        'git checkout master',
        'git rebase --abort || true',
        'git rebase --strategy-option=theirs origin/master'
      ].join(' && ')
    ).run
  end

  private

  def prepare_key
    dir = "#{Dir.home}/.ssh"
    return if File.exist?(dir)
    FileUtils.mkdir_p(dir)
    IO.write("#{dir}/id_rsa", @id_rsa) unless @id_rsa.empty?
    Exec.new(
      [
        'echo "Host *" > ~/.ssh/config',
        'echo "  StrictHostKeyChecking no" >> ~/.ssh/config',
        'echo "  UserKnownHostsFile=~/.ssh/known_hosts" >> ~/.ssh/config',
        'chmod -R 600 ~/.ssh/*'
      ].join(';')
    ).run
  end

  def prepare_git
    Exec.new(
      [
        'GIT=$(git --version)',
        'if [[ "${GIT}" != "git version 2."* ]]',
        'then echo "Git is too old: ${GIT}"',
        'exit -1',
        'fi',
        'git config --global user.email "server@0pdd.com"',
        'git config --global user.name "0pdd.com"'
      ].join(';')
    ).run
  end
end
