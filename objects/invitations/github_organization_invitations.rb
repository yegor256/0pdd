# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'github_organization_invitation'

#
# Invitations to join Github organizations
#
class GithubOrganizationInvitations
  def initialize(github)
    @github = github
  end

  def all
    @github.organization_memberships(state: 'pending').collect do |membership|
      GithubOrganizationInvitation.new(membership, @github)
    end
  end
end
