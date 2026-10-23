# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'uri'
require_relative '../git_repo'
require_relative '../clients/forgejo'

# Forgejo issue adapter. The host is part of the persistent storage/log namespace,
# but the shared template and alerts configuration use the provider "forgejo".
class ForgejoRepo
  attr_reader :repo, :name

  def initialize(client, json, config = {})
    @client = client
    @name = "forgejo-#{client.host}"
    repository = json.fetch('repository')
    name = repository.fetch('full_name')
    valid = %r{\A[a-zA-Z0-9_-]+/[a-zA-Z0-9_-][a-zA-Z0-9_.-]*\z}.match?(name)
    raise ArgumentError, 'Invalid Forgejo repository name' unless valid
    @repo = GitRepo.new(
      uri: "https://#{client.host}/#{name}.git",
      name: name,
      master: repository.fetch('default_branch'),
      target: json.fetch('ref'),
      head_commit_hash: json.fetch('after'),
      **config
    )
  end

  def provider
    'forgejo'
  end

  def exists?
    repository = @client.request(:get, path)
    # Initial support is deliberately public-only: the API token is never put in
    # clone URLs, process arguments or Git configuration.
    !repository[:private]
  rescue ForgejoClient::Error => e
    raise unless e.status == 404
    false
  end

  def issue(issue_id)
    hash = @client.request(:get, "#{path}/issues/#{Integer(issue_id)}")
    milestone = hash[:milestone]
    {
      state: hash[:state],
      author: { id: hash.dig(:user, :id), username: hash.dig(:user, :login) },
      milestone: milestone && { number: milestone[:id], title: milestone[:title] }
    }
  end

  def create_issue(data)
    @client.request(:post, "#{path}/issues", title: data.fetch(:title), body: data.fetch(:description))
  end

  def update_issue(issue_id, data)
    @client.request(:patch, "#{path}/issues/#{Integer(issue_id)}", data)
  end

  def close_issue(issue_id)
    update_issue(issue_id, state: 'closed')
    true
  end

  def labels
    @client.pages("#{path}/labels")
  end

  def add_label(label, color)
    @client.request(:post, "#{path}/labels", name: label, color: color.delete_prefix('#'))
  end

  def add_labels_to_an_issue(issue_id, names)
    available = labels
    ids = names.map do |name|
      available.find { |label| label[:name].casecmp?(name) }.fetch(:id)
    end
    @client.request(:post, "#{path}/issues/#{Integer(issue_id)}/labels", labels: ids)
  end

  def add_comment(issue_id, comment)
    @client.request(:post, "#{path}/issues/#{Integer(issue_id)}/comments", body: comment)
    true
  end

  # Forgejo has no commit-comment endpoint. Keep diagnostics in the server log
  # rather than failing a successfully created/closed issue on a nonexistent API.
  def create_commit_comment(sha, comment)
    puts "#{repository_link}/commit/#{escape(sha)}: #{comment}"
    { html_url: "#{repository_link}/commit/#{escape(sha)}" }
  end

  def list_commits
    @client.pages("#{path}/commits")
  end

  def user(username)
    @client.request(:get, "users/#{escape(username)}")
  end

  def star
    # Starring is cosmetic and would require additional user-write permission.
    true
  end

  def repository_link
    "https://#{@client.host}/#{@repo.name}"
  end

  def collaborators_link
    "#{repository_link}/settings/collaboration"
  end

  def file_link(file)
    "#{repository_link}/src/branch/#{escape(@repo.master)}/#{file.split('/').map { |part| escape(part) }.join('/')}"
  end

  def puzzle_link_for_commit(sha, file, start, stop)
    path = file.split('/').map { |part| escape(part) }.join('/')
    "#{repository_link}/src/commit/#{escape(sha)}/#{path}#L#{Integer(start)}-L#{Integer(stop)}"
  end

  def issue_link(issue_id)
    "#{repository_link}/issues/#{Integer(issue_id)}"
  end

  private

  def path
    "repos/#{@repo.name}"
  end

  def escape(value)
    URI.encode_www_form_component(value.to_s).gsub('+', '%20')
  end
end
