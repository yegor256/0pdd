# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'rack/test'
require_relative 'fake_github'
require_relative 'test__helper'
require_relative '../0pdd'

class PingGithubTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_survives_a_forbidden_notifications_read
    before = Sinatra::Application.settings.github
    gh = FakeGithub.new
    gh.define_singleton_method(:notifications) do
      raise(Octokit::Forbidden.new(status: 403, body: 'no way', response_headers: {}))
    end
    Sinatra::Application.set(:github, gh)
    get('/ping-github')
    assert_predicate(last_response, :ok?)
    assert_includes(last_response.body, 'Octokit::Forbidden')
  ensure
    Sinatra::Application.set(:github, before)
  end
end
