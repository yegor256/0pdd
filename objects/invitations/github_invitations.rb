# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

#
# Invitations in Github
#
class GithubInvitations
  def initialize(github)
    @github = github
  end

  def accept
    @github.user_repository_invitations.each do |i|
      break if @github.rate_limit.remaining < 1000
      puts "Repository invitation #{i['id']} accepted" if @github.accept_repository_invitation(i['id'])
    end
  end

  def accept_single_invitation(repo)
    invitations = @github.user_repository_invitations(repo: repo)
    invitations.map do |i|
      break if @github.rate_limit.remaining < 1000
      "Repository invitation #{repo} accepted" if @github.accept_repository_invitation(i['id'])
    end
  end

  def accept_orgs
    @github.organization_memberships('state' => 'pending').each do |m|
      break if @github.rate_limit.remaining < 1000
      org = m['organization']['login']
      begin
        @github.update_organization_membership(org, 'state' => 'active')
        puts "Invitation for @#{org} accepted"
      rescue Octokit::NotFound
        # puts "Failed to join @#{org} organization: #{e.message}"
        @github.remove_organization_membership(org)
        # puts "Membership in @#{org} organization removed"
      end
    end
  end
end
