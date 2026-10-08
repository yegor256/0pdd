# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative '../objects/forgejo_hook'
require_relative '../objects/tickets/tickets'
require_relative '../objects/puzzles'
require_relative '../0pdd'
require_relative 'fake_storage'

# Forgejo transport, issue adapter and puzzle lifecycle contracts.
class TestForgejo < Minitest::Test
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    connection = Faraday.new(url: 'https://codeberg.org/api/v1/') do |builder|
      builder.adapter :test, @stubs
    end
    @client = ForgejoClient.new('codeberg.org', 'test-token', connection)
    @dir = Dir.mktmpdir('forgejo-test')
    @vcs = ForgejoRepo.new(@client, payload, dir: @dir)
  end

  def teardown
    FileUtils.remove_entry(@dir)
    @stubs.verify_stubbed_calls
  end

  def test_authenticates_json_requests
    @stubs.post('/api/v1/repos/alice/project/issues') do |env|
      assert_equal('token test-token', env.request_headers['Authorization'])
      assert_equal('application/json', env.request_headers['Content-Type'])
      assert_equal({ 'title' => 'Puzzle', 'body' => 'Details' }, JSON.parse(env.body))
      [201, {}, '{"number":7,"html_url":"https://codeberg.org/alice/project/issues/7"}']
    end
    assert_equal(7, @vcs.create_issue(title: 'Puzzle', description: 'Details')[:number])
  end

  def test_separates_host_storage_and_ignores_payload_urls
    assert_equal('forgejo-codeberg.org', @vcs.name)
    other = ForgejoRepo.new(ForgejoClient.new('git.example.org', 'token'), payload, dir: @dir)
    refute_equal(@vcs.name, other.name)
    refute_equal(@vcs.repo.lock, other.repo.lock)
    assert_equal('https://codeberg.org/alice/project.git', @vcs.repo.uri)
    assert_equal('main', @vcs.repo.master)
    assert_predicate(@vcs.repo, :change_in_master?)
  end

  def test_links_to_forgejo_sources
    assert_equal('https://codeberg.org/alice/project/issues/7', @vcs.issue_link(7))
    assert_equal('https://codeberg.org/alice/project/src/branch/main/a%20b.rb', @vcs.file_link('a b.rb'))
    assert_equal(
      'https://codeberg.org/alice/project/src/commit/abc/dir/a%23b.rb#L2-L4',
      @vcs.puzzle_link_for_commit('abc', 'dir/a#b.rb', '2', '4')
    )
  end

  def test_reads_author_and_milestone
    @stubs.get('/api/v1/repos/alice/project/issues/7') do
      [200, {}, '{"state":"open","user":{"id":9,"login":"alice"},"milestone":{"id":3,"title":"v1"}}']
    end
    assert_equal(
      { state: 'open', author: { id: 9, username: 'alice' }, milestone: { number: 3, title: 'v1' } },
      @vcs.issue(7)
    )
  end

  def test_updates_issues
    @stubs.patch('/api/v1/repos/alice/project/issues/7') do |env|
      assert_equal({ 'milestone' => 3 }, JSON.parse(env.body))
      [200, {}, '{"number":7}']
    end
    assert_equal(7, @vcs.update_issue(7, milestone: 3)[:number])
  end

  def test_paginates_labels_and_sends_numeric_ids
    @stubs.get('/api/v1/repos/alice/project/labels?limit=50&page=1') do
      [200, {}, '[{"id":2,"name":"other"}]']
    end
    @stubs.get('/api/v1/repos/alice/project/labels?limit=50&page=2') do
      [200, {}, '[{"id":9,"name":"PDD"}]']
    end
    @stubs.get('/api/v1/repos/alice/project/labels?limit=50&page=3') { [200, {}, '[]'] }
    @stubs.post('/api/v1/repos/alice/project/issues/7/labels') do |env|
      assert_equal({ 'labels' => [9] }, JSON.parse(env.body))
      [200, {}, '[]']
    end
    assert_empty(@vcs.add_labels_to_an_issue(7, ['pdd']))
  end

  def test_creates_labels
    @stubs.post('/api/v1/repos/alice/project/labels') do |env|
      assert_equal({ 'name' => 'pdd', 'color' => 'F74219' }, JSON.parse(env.body))
      [201, {}, '{"id":9,"name":"pdd"}']
    end
    assert_equal(9, @vcs.add_label('pdd', '#F74219')[:id])
  end

  def test_does_not_treat_server_errors_as_absence
    @stubs.get('/api/v1/repos/alice/project') { [503, {}, 'do not expose this body or token'] }
    error = assert_raises(ForgejoClient::Error) { @vcs.exists? }
    assert_equal(503, error.status)
    refute_includes(error.message, 'token')
  end

  def test_reports_missing_repository
    @stubs.get('/api/v1/repos/alice/project') { [404, {}, '{}'] }
    refute_predicate(@vcs, :exists?)
  end

  def test_rejects_private_repository
    @stubs.get('/api/v1/repos/alice/project') { [200, {}, '{"private":true}'] }
    refute_predicate(@vcs, :exists?)
  end

  def test_accepts_public_repository
    @stubs.get('/api/v1/repos/alice/project') { [200, {}, '{"private":false}'] }
    assert_predicate(@vcs, :exists?)
  end

  def test_does_not_follow_redirects_with_credentials
    @stubs.get('/api/v1/repos/alice/project') { [302, { 'Location' => 'https://evil.example' }, ''] }
    assert_raises(ForgejoClient::Error) { @vcs.exists? }
  end

  def test_rejects_unsafe_host_and_repository_names
    ['evil.example/path', 'user@host', 'host:443', '../host'].each do |host|
      assert_raises(ArgumentError) { ForgejoClient.new(host, 'token') }
    end
    assert_raises(ArgumentError) { ForgejoClient.new('codeberg.org', '') }
    json = payload
    json['repository']['full_name'] = 'alice/../../other'
    assert_raises(ArgumentError) { ForgejoRepo.new(@client, json) }
  end

  def test_create_replay_and_remove_puzzle
    FileUtils.mkdir_p(@vcs.repo.path)
    File.write(File.join(@vcs.repo.path, '.0pdd.yml'), "alerts:\n  forgejo:\n    - alice\n")
    calls = []
    @stubs.post('/api/v1/repos/alice/project/issues') do |env|
      calls << :create
      body = JSON.parse(env.body).fetch('body')
      assert_includes(body, 'https://codeberg.org/alice/project/src/commit/')
      [201, {}, '{"number":7,"html_url":"https://codeberg.org/alice/project/issues/7"}']
    end
    @stubs.get('/api/v1/repos/alice/project/issues/7') { [200, {}, '{"state":"open"}'] }
    @stubs.patch('/api/v1/repos/alice/project/issues/7') do |env|
      calls << :close
      assert_equal({ 'state' => 'closed' }, JSON.parse(env.body))
      [200, {}, '{"number":7,"state":"closed"}']
    end
    @stubs.post('/api/v1/repos/alice/project/issues/7/comments') do |env|
      calls << JSON.parse(env.body).fetch('body')
      [201, {}, '{}']
    end
    snapshot = Nokogiri::XML(
      '<puzzles><puzzle><id>1-abc</id><file>a.rb</file><lines>1-2</lines>' \
      '<body>Fix this puzzle</body><ticket>1</ticket><time>2026-01-01T00:00:00Z</time>' \
      '<author>Alice</author><estimate>30</estimate><role>DEV</role></puzzle></puzzles>'
    )
    @vcs.repo.define_singleton_method(:xml) { Nokogiri::XML(snapshot.to_s) }
    storage = FakeStorage.new(@dir)
    tickets = Tickets.new(@vcs)
    puzzles = Puzzles.new(@vcs.repo, storage)
    puzzles.deploy(tickets)
    puzzles.deploy(tickets)
    assert_equal(1, calls.count(:create), 'A repeated snapshot must not create another issue')
    assert(calls.any? { |item| item.to_s.include?('@alice please pay attention') })
    snapshot = Nokogiri::XML('<puzzles/>')
    puzzles.deploy(tickets)
    puzzles.deploy(tickets)
    assert_equal(1, calls.count(:close), 'A removed puzzle must be closed exactly once')
    refute_empty(storage.load.xpath('//issue[@closed]'))
  end

  def test_runs_through_the_production_job_and_ticket_decorators
    original_dynamo = Sinatra::Application.settings.dynamo
    original_mail = Mail.delivery_method
    Sinatra::Application.set :dynamo, Aws::DynamoDB::Client.new(stub_responses: true)
    Mail.defaults { delivery_method :test }
    FileUtils.mkdir_p(@vcs.repo.path)
    File.write(File.join(@vcs.repo.path, '.0pdd.yml'), "alerts:\n  suppress:\n    - on-scope\n")
    snapshot = Nokogiri::XML(File.read('test-assets/puzzles/simple.xml')).at_xpath('/test/snapshot/puzzles').to_s
    @vcs.repo.define_singleton_method(:push) { nil }
    @vcs.repo.define_singleton_method(:xml) { Nokogiri::XML(snapshot) }
    @stubs.post('/api/v1/repos/alice/project/issues') do
      [201, {}, '{"number":7,"html_url":"https://codeberg.org/alice/project/issues/7"}']
    end
    storage = FakeStorage.new(@dir)
    application = Sinatra::Application.new!
    application.define_singleton_method(:storage) { |_repo, _vcs| storage }
    application.send(:process_request, @vcs)
    assert_equal('7', storage.load.at_xpath('//issue').text)
    assert_equal('https://codeberg.org/alice/project/issues/7 opened', Mail::TestMailer.deliveries.last.subject)
  ensure
    Sinatra::Application.set :dynamo, original_dynamo
    Mail.defaults { delivery_method original_mail.class, original_mail.settings }
  end

  def test_failed_scan_preserves_issue_state
    storage = FakeStorage.new(@dir, '<puzzles><puzzle alive="true"><id>1-abc</id><issue>7</issue></puzzle></puzzles>')
    before = storage.load.to_s
    @vcs.repo.define_singleton_method(:xml) { raise UserError, 'scan failed' }
    assert_raises(UserError) { Puzzles.new(@vcs.repo, storage).deploy(Tickets.new(@vcs)) }
    assert_equal(before, storage.load.to_s)
  end

  private

  def payload
    {
      'repository' => {
        'full_name' => 'alice/project', 'default_branch' => 'main',
        'clone_url' => 'https://evil.example/repo.git', 'ssh_url' => 'git@evil.example:repo.git'
      },
      'ref' => 'refs/heads/main', 'after' => 'a' * 40
    }
  end
end
