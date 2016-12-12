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

require 'fileutils'
require 'pdd'
require_relative 'config'
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

  def xml
    Nokogiri::XML(
      PDD::Base.new(
        source: @path
      ).xml
    )
  end

  def push
    prepare
    if File.exist?(@path)
      pull
    else
      clone
    end
  end

  def clone
    Exec.new(
      'git clone',
      '--depth=1',
      '--quiet',
      @uri,
      @path
    ).run
  end

  def pull
    Exec.new(
      'git',
      "--git-dir=#{@path}/.git",
      'pull',
      '--quiet'
    ).run
  end

  private

  def prepare
    dir = "#{Dir.home}/.ssh"
    return if File.exist?(dir)
    FileUtils.mkdir_p(dir)
    priv = "#{dir}/id_rsa"
    IO.write(priv, @id_rsa) unless @id_rsa.empty?
    Exec.new(
      'set -x;',
      'set -e;',
      'echo "Host *" > ~/.ssh/config;',
      'echo "  StrictHostKeyChecking no" >> ~/.ssh/config;',
      'echo "  UserKnownHostsFile=~/.ssh/known_hosts" >> ~/.ssh/config;',
      'chmod -R 600 ~/.ssh/*'
    ).run
  end
end
