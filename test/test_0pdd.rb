# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'rack/test'
require_relative 'test__helper'
require_relative '../0pdd'

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
end
