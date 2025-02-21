# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'octokit'

#
# Github client
# API: http://octokit.github.io/octokit.rb/method_list.html
#
class Github
  def initialize(config = {})
    @config = config
  end

  def client
    if @config['testing']
      require_relative '../../test/fake_github'
      FakeGithub.new
    else
      args = {}
      args[:access_token] = @config['github']['token'] if @config['github']
      Octokit.connection_options = {
        request: {
          timeout: 20,
          open_timeout: 20
        }
      }
      Octokit.auto_paginate = true
      Octokit::Client.new(args)
    end
  end
end
