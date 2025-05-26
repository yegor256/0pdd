# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'base64'
require 'fileutils'
require 'pdd'
require 'qbash'
require 'shellwords'
require 'tempfile'
require 'tmpdir'
require 'yaml'
require_relative 'user_error'

#
# Repository in Git
#
class GitRepo
  attr_reader :uri, :name, :path, :master, :head_commit_hash, :target

  def initialize(
    uri:,
    name:,
    master: 'master',
    head_commit_hash: '',
    **options
  )
    @id = Base64.encode64(uri).gsub(%r{[\s=/]+}, '')
    @name = name
    @dir = options[:dir] || Dir.mktmpdir('0pdd')
    @path = "#{@dir}/#{@id}"
    @uri = uri
    @id_rsa = options[:id_rsa] || ''
    @master = master
    @head_commit_hash = head_commit_hash
    @target = options[:target] || 'master'
  end

  def lock
    "/tmp/0pdd-locks/#{@id}.txt"
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
    raise "Path is absent: #{@path}" unless File.exist?(@path)
    Tempfile.open do |f|
      begin
        qbash("cd #{Shellwords.escape(@path)} && pdd -v -f #{Shellwords.escape(f.path)}")
      rescue StandardError => e
        raise UserError, e.message
      end
      Nokogiri::XML(File.read(f))
    end
  end

  def push
    if File.exist?(@path)
      pull
    else
      clone
    end
  end

  def change_in_master?
    "refs/heads/#{master}".eql?(target)
  end

  private

  def clone
    prepare_key
    prepare_git
    qbash(['git clone', '--depth=1', '--quiet', Shellwords.escape(@uri), Shellwords.escape(@path)])
  end

  def pull
    prepare_key
    prepare_git
    qbash(
      [
        "cd #{Shellwords.escape(@path)}",
        "master=#{Shellwords.escape(@master)}",
        'git config --local core.autocrlf false',
        'git reset origin/${master} --hard --quiet',
        'git clean --force -d',
        'git fetch --quiet',
        'git checkout origin/${master}',
        'git rebase --abort || true',
        'git rebase --autostash --strategy-option=theirs origin/${master}'
      ].join(' && ')
    )
  end

  def prepare_key
    dir = "#{Dir.home}/.ssh"
    return if File.exist?(dir)
    FileUtils.mkdir_p(dir)
    File.write("#{dir}/id_rsa", @id_rsa) unless @id_rsa.empty?
    qbash(
      [
        'echo "Host *" > ~/.ssh/config',
        'echo "  StrictHostKeyChecking no" >> ~/.ssh/config',
        'echo "  UserKnownHostsFile=~/.ssh/known_hosts" >> ~/.ssh/config',
        'chmod -R 600 ~/.ssh/*'
      ].join(';')
    )
  end

  def prepare_git
    qbash(
      [
        'GIT=$(git --version)',
        'if [[ "${GIT}" != "git version 2."* ]]',
        'then echo "Git is too old: ${GIT}"',
        'exit -1',
        'fi'
      ].join(';')
    )
    return if ENV['RACK_ENV'] == 'test'
    qbash(
      [
        'if ! git config --get --global user.email',
        'then git config --global user.email "server@0pdd.com"',
        'fi',
        'if ! git config --get --global user.name',
        'then git config --global user.name "0pdd.com"',
        'fi'
      ].join(';')
    )
  end
end
