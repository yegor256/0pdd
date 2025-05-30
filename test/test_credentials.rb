# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'mail'
require 'yaml'
require 'octokit'
require 'tmpdir'
require 'aws-sdk-dynamodb'
require_relative 'test__helper'
require_relative '../objects/storage/s3'
require_relative '../objects/tickets/tickets'
require_relative '../objects/log'
require_relative '../objects/vcs/github'
require_relative '../objects/git_repo'

class CredentialsTest < Minitest::Test
  def test_connects_to_git_via_ssh
    cfg = config
    Dir.mktmpdir 'test' do |d|
      repo = GitRepo.new(
        uri: 'git@github.com:yegor256/0pdd',
        name: 'yegor256/0pdd',
        id_rsa: cfg['id_rsa'],
        dir: d
      )
      repo.push
      refute_nil(repo.xml.xpath('//puzzles'))
    end
  end

  def test_connects_to_aws_dynamo
    cfg = config
    dynamo = Aws::DynamoDB::Client.new(
      region: cfg['dynamo']['region'],
      access_key_id: cfg['dynamo']['key'],
      secret_access_key: cfg['dynamo']['secret']
    )
    refute(Log.new(dynamo, 'yegor256/0pdd').exists('some stupid tag'))
  end

  def test_connects_to_github
    cfg = config
    github = Octokit::Client.new(
      access_token: cfg['github']['token']
    )
    tickets = Tickets.new(
      GithubRepo.new(
        github,
        {
          'repository' => {
            'full_name' => 'yegor256/0pdd',
            'url' => 'https://github.com/yegor256/0pdd',
            'master_branch' => 'master'
          },
          'ref' => 'master',
          'head_commit' => {
            'id' => '---'
          }
        }
      )
    )
    tickets.close(
      Nokogiri::XML(
        '<puzzle><id>AA</id><issue>1</issue></puzzle>'
      ).xpath('/puzzle')
    )
  end

  def test_connects_to_aws_s3
    cfg = config
    storage = S3.new(
      'yegor256/0pdd.xml',
      cfg['s3']['bucket'],
      cfg['s3']['region'],
      cfg['s3']['key'],
      cfg['s3']['secret']
    )
    refute_nil(storage.load.xpath('//puzzles'))
  end

  def test_sends_email_via_smtp
    cfg = config
    Mail.defaults do
      delivery_method(
        :smtp,
        address: cfg['smtp']['host'],
        port: cfg['smtp']['port'],
        user_name: cfg['smtp']['user'],
        password: cfg['smtp']['password'],
        domain: '0pdd.com',
        enable_starttls_auto: true
      )
    end
    mail = Mail.new do
      from '0pdd <no-reply@0pdd.com>'
      to 'admin@0pdd.com'
      subject 'Test email, ignore it'
      text_part do
        content_type 'text/plain; charset=UTF-8'
        body 'It it a test email, ignore it.'
      end
    end
    mail.deliver!
  end

  private

  def config
    file = File.join(File.dirname(__FILE__), '../config.yml')
    file = ENV['PDD_CONFIG'] if ENV['PDD_CONFIG']
    skip('...') unless File.exist?(file)
    YAML.safe_load(File.open(file))
  end
end
