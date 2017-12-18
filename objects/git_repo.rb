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
require 'tmpdir'
require 'tempfile'
require 'yaml'
require 'shellwords'
require_relative 'exec'
require_relative 'user_error'

#
# Repository in Git
#
class GitRepo
  def initialize(
    name:, dir: Dir.mktmpdir('0pdd'),
    uri: "git@github.com:#{name}",
    id_rsa: '',
    master: 'master'
  )
    @name = name
    @path = "#{dir}/#{@name}"
    @uri = uri
    @id_rsa = id_rsa
    @master = master
  end

  def lock
    "/tmp/0pdd-locks/#{@name}.txt"
  end

  def config
    f = File.join(@path, '.0pdd.yml')
    if File.exist?(f)
      YAML.safe_load(File.open(f))
    else
      {}
    end
  end

  def xml
    tmp = Tempfile.new('pdd.xml')
    raise "Path is absent: #{@path}" unless File.exist?(@path)
    begin
      Exec.new("cd #{@path} && pdd -v -f #{tmp.path}").run
    rescue Exec::Error => e
      raise UserError, e.message if e.code == 1
      raise e
    end
    Nokogiri::XML(File.open(tmp))
  end

  def push
    if File.exist?(@path)
      pull
    else
      clone
    end
  end

  private

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
        'git config --local core.autocrlf false',
        "git reset #{Shellwords.escape('origin/' + @master)} --hard --quiet",
        'git clean --force -d',
        'git fetch --quiet',
        "git checkout #{Shellwords.escape(@master)}",
        'git rebase --abort || true',
        'git stash',
        "git rebase --strategy-option=theirs \
#{Shellwords.escape("origin/#{@master}")}"
      ].join(' && ')
    ).run
  end

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
        'fi'
      ].join(';')
    ).run
    return if ENV['RACK_ENV'] == 'test'
    Exec.new(
      [
        'if ! git config --get --global user.email',
        'then git config --global user.email "server@0pdd.com"',
        'fi',
        'if ! git config --get --global user.name',
        'then git config --global user.name "0pdd.com"',
        'fi'
      ].join(';')
    ).run
  end
end
