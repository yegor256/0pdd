# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'gitlab'

#
# Gitlab client
# API: https://github.com/NARKOZ/gitlab
#
class GitlabClient
  def initialize(config = {})
    @config = config
  end

  def client
    if @config['testing']
      require_relative '../../test/fake_gitlab'
      FakeGitlab.new
    else
      token = @config['gitlab']['token'] if @config['gitlab']
      Gitlab.client(
        endpoint: 'https://gitlab.com/api/v4',
        private_token: token,
        httparty: {
          headers: { 'Cookie' => 'gitlab_canary=true' }
        }
      )
    end
  end
end
