# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'rubygems'
require 'jira-ruby'

#
# Jira client
# API: https://github.com/sumoheavy/jira-ruby
#
class JiraClient
  def initialize(config = {})
    @config = config
  end

  def client
    if @config['testing']
      # require_relative '../../test/fake_jira'
      # FakeJira.new
    else
      username = @config['jira']['username'] if @config['jira']
      token = @config['jira']['token'] if @config['jira']
      options = {
        username: username,
        password: token,
        site: 'http://localhost:8080/', # or 'https://<your_subdomain>.atlassian.net/' # often blank
        auth_type: :basic,
        read_timeout: 120
      }
      JIRA::Client.new(options)
    end
  end
end
