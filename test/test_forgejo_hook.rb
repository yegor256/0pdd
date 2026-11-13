# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'rack/test'
require_relative 'test__helper'
require_relative '../0pdd'

# HTTP webhook validation and dispatch, without external network or detached jobs.
class TestForgejoHook < Minitest::Test
  include Rack::Test::Methods

  # Adapt Faraday's keyword default-adapter options to its test adapter.
  class Transport < Faraday::Adapter::Test
    def initialize(app, options = {})
      super(app, options.fetch(:stubs))
    end
  end

  # Record the actual adapter dispatched by the production route.
  class App < Sinatra::Application
    attr_reader :processed

    def process_request(vcs)
      settings.processed << vcs
    end
  end

  def app
    App
  end

  def setup
    @config = {
      'codeberg.org' => { 'token' => 'test-token', 'repositories' => { 'alice/project' => 'test-secret' } }
    }
    app.set :config, Sinatra::Application.settings.config.merge('forgejo' => @config)
    app.set :processed, []
    @stubs = Faraday::Adapter::Test::Stubs.new
    @adapter = Faraday.default_adapter
    @options = Faraday.default_adapter_options
    Faraday.default_adapter = Transport
    Faraday.default_adapter_options = { stubs: @stubs }
    @payload = {
      'repository' => { 'full_name' => 'alice/project', 'default_branch' => 'main' },
      'ref' => 'refs/heads/main', 'after' => 'a' * 40
    }
  end

  def teardown
    Faraday.default_adapter = @adapter
    Faraday.default_adapter_options = @options
    @stubs.verify_stubbed_calls
    app.settings.processed.each { |vcs| FileUtils.remove_entry(File.dirname(vcs.repo.path)) }
  end

  def test_dispatches_signed_default_branch_update
    @stubs.get('/api/v1/repos/alice/project') { [200, {}, '{"private":false}'] }
    deliver
    assert_equal(200, last_response.status, last_response.body)
    assert_equal(1, app.settings.processed.size)
    assert_equal('forgejo-codeberg.org', app.settings.processed.first.name)
    assert_equal('a' * 40, app.settings.processed.first.repo.head_commit_hash)
  end

  def test_rejects_unknown_host
    deliver(host: 'evil.example')
    assert_equal(404, last_response.status)
    assert_empty(app.settings.processed)
  end

  def test_rejects_unconfigured_repository
    @config['codeberg.org']['repositories'].clear
    deliver
    assert_equal(404, last_response.status)
    assert_empty(app.settings.processed)
  end

  def test_cannot_use_one_repository_secret_for_another
    @payload['repository']['full_name'] = 'alice/other'
    deliver
    assert_equal(400, last_response.status)
    assert_empty(app.settings.processed)
  end

  def test_rejects_missing_signature
    deliver(headers: { 'HTTP_X_FORGEJO_SIGNATURE' => '' })
    assert_equal(401, last_response.status)
    assert_empty(app.settings.processed)
  end

  def test_rejects_tampered_body
    deliver(headers: { 'HTTP_X_FORGEJO_SIGNATURE' => OpenSSL::HMAC.hexdigest('SHA256', 'test-secret', '{}') })
    assert_equal(401, last_response.status)
    assert_empty(app.settings.processed)
  end

  def test_rejects_unconfigured_secret
    @config['codeberg.org']['repositories']['alice/project'] = ''
    deliver
    assert_equal(503, last_response.status)
    assert_empty(app.settings.processed)
  end

  def test_rejects_non_push_event
    deliver(headers: { 'HTTP_X_FORGEJO_EVENT' => 'issues' })
    assert_equal(400, last_response.status)
    assert_empty(app.settings.processed)
  end

  def test_rejects_non_json_content
    deliver(headers: { 'CONTENT_TYPE' => 'application/x-www-form-urlencoded' })
    assert_equal(415, last_response.status)
    assert_empty(app.settings.processed)
  end

  def test_rejects_malformed_json
    deliver(body: '{')
    assert_equal(400, last_response.status)
    assert_empty(app.settings.processed)
  end

  def test_rejects_incomplete_payload
    deliver(body: '{"repository":{}}')
    assert_equal(400, last_response.status)
    assert_empty(app.settings.processed)
  end

  def test_rejects_non_object_payload
    deliver(body: '[]')
    assert_equal(400, last_response.status)
    assert_empty(app.settings.processed)
  end

  def test_rejects_invalid_repository_path
    @payload['repository']['full_name'] = 'alice/../../secret'
    deliver
    assert_equal(400, last_response.status)
    assert_empty(app.settings.processed)
  end

  def test_ignores_feature_branch
    @payload['ref'] = 'refs/heads/feature'
    deliver
    assert_equal(200, last_response.status)
    assert_empty(app.settings.processed)
  end

  def test_ignores_tags
    @payload['ref'] = 'refs/tags/main'
    deliver
    assert_equal(200, last_response.status)
    assert_empty(app.settings.processed)
  end

  def test_ignores_deleted_branch
    @payload['deleted'] = true
    deliver
    assert_equal(200, last_response.status)
    assert_empty(app.settings.processed)
  end

  def test_ignores_zero_commit
    @payload['after'] = '0' * 40
    deliver
    assert_equal(200, last_response.status)
    assert_empty(app.settings.processed)
  end

  def test_rejects_private_repository_before_dispatch
    @stubs.get('/api/v1/repos/alice/project') { [200, {}, '{"private":true}'] }
    deliver
    assert_equal(400, last_response.status)
    assert_empty(app.settings.processed)
  end

  private

  def deliver(host: 'codeberg.org', body: JSON.generate(@payload), headers: {})
    post(
      "/hook/forgejo/#{host}/alice/project", body,
      {
        'CONTENT_TYPE' => 'application/json',
        'HTTP_X_FORGEJO_EVENT' => 'push',
        'HTTP_X_FORGEJO_SIGNATURE' => OpenSSL::HMAC.hexdigest('SHA256', 'test-secret', body)
      }.merge(headers)
    )
  end
end
