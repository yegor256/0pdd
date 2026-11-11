# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'rack/test'
require 'rackup/handler/webrick'
require_relative 'test__helper'
require_relative '../0pdd'

# Emulates what Rackup::Handler::WEBrick passes to the app as +rack.input+
# in production: fiber-based input, consumed chunk by chunk, without a
# +#rewind+ method. See https://github.com/yegor256/0pdd/issues/572
class FakeWebrickRequest
  def initialize(*chunks)
    @chunks = chunks
  end

  def body(&block)
    @chunks.each(&block)
  end
end

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_renders_version
    get('/version')
    assert_predicate(last_response, :ok?)
  end

  def test_robots_txt
    get('/robots.txt')
    assert_predicate(last_response, :ok?)
  end

  def test_it_renders_home_page
    get('/')
    assert_predicate(last_response, :ok?)
    assert_includes(last_response.body, '0pdd')
  end

  def test_renders_some_pages
    [
      '/',
      '/robots.txt',
      '/version',
      '/puzzles.xsd',
      '/logout',
      '/css/main.css'
    ].each do |page|
      get(page)
      assert_operator(last_response.status, :<, 400, "Failed to render #{page}")
    end
  end

  def test_it_renders_puzzles_xsd
    get('/puzzles.xsd')
    assert_predicate(last_response, :ok?)
    assert_includes(last_response.body, '<xs:schema')
  end

  def test_renders_log_page
    repo = 'yegor256/0pdd'
    log = Log.new(Dynamo.new.aws, repo)
    log.put('some-tag', 'some text here')
    get("/log?name=#{repo}")
    assert_predicate(last_response, :ok?, last_response.body)
    assert_includes(last_response.body, repo, last_response.body)
    assert_includes(last_response.body, 'some text', last_response.body)
  end

  def test_renders_log_item
    repo = 'yegor256/0pdd'
    log = Log.new(Dynamo.new.aws, repo)
    tag = 'some-tag'
    log.put(tag, 'some text here')
    get("/log-item?repo=#{repo}&tag=#{tag}")
    assert_predicate(last_response, :ok?, last_response.body)
    assert_includes(last_response.body, repo, last_response.body)
    assert_includes(last_response.body, 'some text', last_response.body)
  end

  def test_renders_page_not_found
    get('/the-url-that-is-absent')
    assert_equal(404, last_response.status)
  end

  def test_it_understands_push_from_github
    headers = {
      'CONTENT_TYPE' => 'application/json',
      'HTTP_USER_AGENT' => 'GitHub-Hookshot',
      'HTTP_X_GITHUB_EVENT' => 'push'
    }
    post(
      '/hook/github',
      ['{"head_commit":{"id":"-"},',
       '"repository":{"url":"localhost",',
       '"full_name":"yegor256-one/com.github.0pdd-test"},',
       '"ref":"refs/heads/master"}'].join,
      headers
    )
    assert_predicate(last_response, :ok?)
    assert_includes(last_response.body, 'Thanks')
  end

  def test_it_understands_form_push_from_github
    headers = {
      'CONTENT_TYPE' => 'application/x-www-form-urlencoded',
      'HTTP_USER_AGENT' => 'GitHub-Hookshot',
      'HTTP_X_GITHUB_EVENT' => 'push'
    }
    payload = [
      '{"head_commit":{"id":"-"},',
      '"repository":{"url":"localhost",',
      '"full_name":"yegor256-one/com.github.0pdd-test"},',
      '"ref":"refs/heads/master"}'
    ].join
    post(
      '/hook/github',
      Rack::Utils.build_query(payload: payload),
      headers
    )
    assert_predicate(last_response, :ok?)
    assert_includes(last_response.body, 'Thanks')
  end

  def test_it_understands_form_push_from_github_with_webrick_input
    payload = [
      '{"head_commit":{"id":"-"},',
      '"repository":{"url":"localhost",',
      '"full_name":"yegor256-one/com.github.0pdd-test"},',
      '"ref":"refs/heads/master"}'
    ].join
    status, _headers, body = Sinatra::Application.call(
      webrick_env('application/x-www-form-urlencoded', Rack::Utils.build_query(payload: payload))
    )
    assert_equal(200, status)
    assert_includes(body.join, 'Thanks')
  end

  def test_it_understands_json_push_from_github_with_webrick_input
    payload = [
      '{"head_commit":{"id":"-"},',
      '"repository":{"url":"localhost",',
      '"full_name":"yegor256-one/com.github.0pdd-test"},',
      '"ref":"refs/heads/master"}'
    ].join
    status, _headers, body = Sinatra::Application.call(
      webrick_env('application/json', payload)
    )
    assert_equal(200, status)
    assert_includes(body.join, 'Thanks')
  end

  def test_rejects_github_push_without_payload
    headers = {
      'CONTENT_TYPE' => 'application/x-www-form-urlencoded',
      'HTTP_USER_AGENT' => 'GitHub-Hookshot',
      'HTTP_X_GITHUB_EVENT' => 'push'
    }
    post('/hook/github', 'foo=bar', headers)
    assert_equal(400, last_response.status)
    assert_includes(
      last_response.body,
      'URL-encoded content is expected in the "payload" query parameter'
    )
  end

  def test_it_ignores_push_from_github_to_not_master
    headers = {
      'CONTENT_TYPE' => 'application/json',
      'HTTP_USER_AGENT' => 'GitHub-Hookshot',
      'HTTP_X_GITHUB_EVENT' => 'push'
    }
    post(
      '/hook/github',
      ['{"head_commit":{"id":"-"},',
       '"repository":{"url":"localhost",',
       '"full_name":"yegor256-one/com.github.0pdd-test"},',
       '"ref":"refs/heads/main"}'].join,
      headers
    )
    assert_predicate(last_response, :ok?)
    assert_includes(last_response.body, 'Thanks')
    assert_includes(last_response.body, 'nothing is done')
  end

  def test_it_accepts_push_from_github_to_not_default_master
    headers = {
      'CONTENT_TYPE' => 'application/json',
      'HTTP_USER_AGENT' => 'GitHub-Hookshot',
      'HTTP_X_GITHUB_EVENT' => 'push'
    }
    post(
      '/hook/github',
      ['{"head_commit":{"id":"-"},',
       '"repository":{"url":"localhost",',
       '"master_branch": "main",',
       '"full_name":"yegor256-one/com.github.0pdd-test"},',
       '"ref":"refs/heads/main"}'].join,
      headers
    )
    assert_predicate(last_response, :ok?)
    assert_includes(last_response.body, 'Thanks')
    refute_includes(last_response.body, 'nothing is done')
  end

  def test_it_ignore_push_from_github_to_not_default_master
    headers = {
      'CONTENT_TYPE' => 'application/json',
      'HTTP_USER_AGENT' => 'GitHub-Hookshot',
      'HTTP_X_GITHUB_EVENT' => 'push'
    }
    post(
      '/hook/github',
      ['{"head_commit":{"id":"-"},',
       '"repository":{"url":"localhost",',
       '"master_branch": "main",',
       '"full_name":"yegor256-one/com.github.0pdd-test"},',
       '"ref":"refs/heads/master"}'].join,
      headers
    )
    assert_predicate(last_response, :ok?)
    assert_includes(last_response.body, 'Thanks')
    assert_includes(last_response.body, 'nothing is done')
  end

  def test_it_understands_push_from_gitlab
    headers = {
      'CONTENT_TYPE' => 'application/json',
      'HTTP_USER_AGENT' => 'GitLab 16.6',
      'HTTP_X_GITLAB_EVENT' => 'Push Hook'
    }
    post(
      '/hook/gitlab',
      ['{"checkout_sha": "da1560886d4",',
       '"project":{"url":"localhost",',
       '"path_with_namespace":"yegor256-one/com.github.0pdd-test"},',
       '"ref":"refs/heads/master"}'].join,
      headers
    )
    assert_predicate(last_response, :ok?)
    assert_includes(last_response.body, 'Thanks')
  end

  def test_it_understands_form_push_from_gitlab
    headers = {
      'CONTENT_TYPE' => 'application/x-www-form-urlencoded',
      'HTTP_USER_AGENT' => 'GitLab 16.6',
      'HTTP_X_GITLAB_EVENT' => 'Push Hook'
    }
    payload = [
      '{"checkout_sha": "da1560886d4",',
      '"project":{"url":"localhost",',
      '"path_with_namespace":"yegor256-one/com.github.0pdd-test"},',
      '"ref":"refs/heads/master"}'
    ].join
    post(
      '/hook/gitlab',
      Rack::Utils.build_query(payload: payload),
      headers
    )
    assert_predicate(last_response, :ok?)
    assert_includes(last_response.body, 'Thanks')
  end

  def test_it_ignores_push_from_gitlab_to_not_master
    headers = {
      'CONTENT_TYPE' => 'application/json',
      'HTTP_USER_AGENT' => 'GitLab 16.6',
      'HTTP_X_GITLAB_EVENT' => 'Push Hook'
    }
    post(
      '/hook/gitlab',
      ['{"checkout_sha": "da1560886d4",',
       '"project":{"url":"localhost",',
       '"path_with_namespace":"yegor256-one/com.github.0pdd-test"},',
       '"ref":"refs/heads/main"}'].join,
      headers
    )
    assert_predicate(last_response, :ok?)
    assert_includes(last_response.body, 'Thanks')
    assert_includes(last_response.body, 'nothing is done')
  end

  def test_it_accepts_push_from_gitlab_to_not_default_master
    headers = {
      'CONTENT_TYPE' => 'application/json',
      'HTTP_USER_AGENT' => 'GitLab 16.6',
      'HTTP_X_GITLAB_EVENT' => 'Push Hook'
    }
    post(
      '/hook/gitlab',
      ['{"checkout_sha": "da1560886d4",',
       '"project":{"url":"localhost",',
       '"default_branch": "main",',
       '"path_with_namespace":"yegor256-one/com.github.0pdd-test"},',
       '"ref":"refs/heads/main"}'].join,
      headers
    )
    assert_predicate(last_response, :ok?)
    assert(last_response.body.start_with?('Thanks'))
    refute_includes(last_response.body, 'nothing is done')
  end

  def test_it_ignores_push_from_gitlab_to_not_default_master
    headers = {
      'CONTENT_TYPE' => 'application/json',
      'HTTP_USER_AGENT' => 'GitLab 16.6',
      'HTTP_X_GITLAB_EVENT' => 'Push Hook'
    }
    post(
      '/hook/gitlab',
      ['{"checkout_sha": "da1560886d4",',
       '"project":{"url":"localhost",',
       '"default_branch": "main",',
       '"path_with_namespace":"yegor256-one/com.github.0pdd-test"},',
       '"ref":"refs/heads/master"}'].join,
      headers
    )
    assert_predicate(last_response, :ok?)
    assert_includes(last_response.body, 'Thanks')
    assert_includes(last_response.body, 'nothing is done')
  end

  def test_renders_html_puzzles
    get('/p?name=yegor256/pdd')
    assert_predicate(last_response, :ok?)
    html = last_response.body
    assert(
      html.include?('<html') &&
        html.include?('<title>'),
      "broken HTML: #{html}"
    )
  end

  def test_snapshots_unavailable_repo
    get('/snapshot?name=yegor256/0pdd_foobar_unavailable')
    assert_equal(400, last_response.status)
  end

  def test_renders_svg_puzzles
    get('/svg?name=yegor256/pdd')
    assert_predicate(last_response, :ok?)
    svg = last_response.body
    File.write('/tmp/0pdd-button.svg', svg)
    assert_includes(
      svg, '<svg ',
      "broken SVG: #{svg}"
    )
  end

  def test_renders_xml_puzzles
    get('/xml?name=yegor256/pdd')
    assert_predicate(last_response, :ok?)
    xml = last_response.body
    assert_includes(
      xml, '<puzzles ',
      "broken XML: #{xml}"
    )
  end

  def test_rejects_invalid_repo_name
    get('/svg?name=yego256/pdd+a')
    refute_predicate(last_response, :ok?)
  end

  def test_not_found
    get('/unknown_path')
    assert_equal(404, last_response.status)
    assert_equal('text/html;charset=utf-8', last_response.content_type)
  end

  private

  # Builds a Rack env the same way Rackup::Handler::WEBrick#service does
  # in production, with the non-rewindable fiber-based rack.input (#572).
  def webrick_env(content_type, body)
    {
      'REQUEST_METHOD' => 'POST',
      'SCRIPT_NAME' => '',
      'PATH_INFO' => '/hook/github',
      'QUERY_STRING' => '',
      'SERVER_NAME' => 'localhost',
      'SERVER_PORT' => '443',
      'CONTENT_TYPE' => content_type,
      'CONTENT_LENGTH' => body.bytesize.to_s,
      'HTTP_USER_AGENT' => 'GitHub-Hookshot/abc123',
      'HTTP_X_GITHUB_EVENT' => 'push',
      'rack.version' => Rack::VERSION,
      'rack.url_scheme' => 'https',
      'rack.input' => Rackup::Handler::WEBrick::Input.new(
        FakeWebrickRequest.new(
          body.byteslice(0, body.bytesize / 2),
          body.byteslice(body.bytesize / 2, body.bytesize)
        )
      ),
      'rack.errors' => $stderr,
      'rack.multithread' => true,
      'rack.multiprocess' => false,
      'rack.run_once' => false,
      'rack.hijack?' => true
    }
  end
end
