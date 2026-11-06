# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'ostruct'
require_relative 'test__helper'
require_relative '../objects/tickets/tickets'
require_relative '../objects/vcs/jira'

# JiraRepo test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2026 Yegor Bugayenko
# License:: MIT
class TestJira < Minitest::Test
  def test_reads_issue_as_contract_hash
    issue = jira_repo(
      {
        'status' => {
          'statusCategory' => {
            'key' => 'done'
          }
        },
        'reporter' => {
          'accountId' => 'abc',
          'name' => 'yegor256',
          'displayName' => 'Yegor Bugayenko'
        }
      }
    ).issue('JRA-1')
    assert_equal('closed', issue[:state])
    assert_equal({ id: 'abc', username: 'yegor256' }, issue[:author])
    assert_nil(issue[:milestone])
  end

  def test_reads_unfinished_issue_as_open
    issue = jira_repo(
      {
        'status' => {
          'statusCategory' => {
            'key' => 'indeterminate'
          }
        }
      }
    ).issue('JRA-2')
    assert_equal('open', issue[:state])
  end

  def test_wraps_http_error_on_issue_read
    error = assert_raises(RuntimeError) do
      jira_repo({}, error: jira_error('not accessible')).issue('JRA-3')
    end
    assert_equal("Can't read JIRA issue JRA-3: not accessible", error.message)
  end

  def test_notify_rescues_jira_http_errors
    error = jira_error('gone')
    vcs = Object.new
    vcs.define_singleton_method(:issue) { |_issue| raise error }
    vcs.define_singleton_method(:add_comment) do |_issue, _comment|
      raise 'comment should not be posted'
    end
    stdout, = capture_io { Tickets.new(vcs).notify('JRA-4', 'please check') }
    assert_includes(stdout, "can't comment: gone")
  end

  private

  def jira_repo(fields, error: nil)
    finder = Object.new
    finder.define_singleton_method(:find) do |_issue|
      raise error unless error.nil?
      OpenStruct.new(fields: fields)
    end
    JiraRepo.new(jira_client(finder), jira_json)
  end

  def jira_client(finder)
    Class.new do
      def initialize(finder)
        @finder = finder
      end

      def method_missing(name, *args)
        return @finder if name == :Issue
        super
      end

      def respond_to_missing?(name, include_private = false)
        name == :Issue || super
      end
    end.new(finder)
  end

  def jira_json
    {
      'repository' => {
        'ssh_url' => 'git@example.com:yegor256/0pdd.git',
        'full_name' => 'yegor256/0pdd',
        'master_branch' => 'master'
      },
      'head_commit' => {
        'id' => 'abcdef'
      }
    }
  end

  def jira_error(message)
    JIRA::HTTPError.new(OpenStruct.new(message: message, body: nil))
  end
end
