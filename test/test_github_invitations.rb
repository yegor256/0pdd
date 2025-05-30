# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative 'fake_github'
require_relative '../objects/invitations/github_invitations'

# GithubInvitations test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2025 Yegor Bugayenko
# License:: MIT
class TestGithubInvitation < Minitest::Test
  def test_accepts_organization_invitations
    organizations = %w[github google microsoft zerocracy]
    orgs = %w[github zerocracy]
    github = FakeGithub.new(
      memberships: organizations.collect do |org|
        {
          'state' => orgs.include?(org) ? 'active' : 'pending',
          'organization' => {
            'login' => org
          }
        }
      end
    )
    invitations = GithubInvitations.new(github)
    invitations.accept_orgs
    organizations.map do |org|
      assert(
        github.organization_memberships.find do |m|
          m['state'] == 'active' && m['organization']['login'] == org
        end
      )
    end
  end

  def test_accepts_repository_invitations
    repositories = %w[yegor256/0pdd yegor256/sixnines]
    github = FakeGithub.new(
      invitations: repositories.enum_for(:each_with_index).collect do |repo, i|
        {
          'id' => i,
          'repository' => {
            'name' => repo
          }
        }
      end
    )
    GithubInvitations.new(github).accept
    repositories.map { |repo| assert_includes(github.repositories, repo) }
  end
end
