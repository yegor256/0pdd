# Copyright (c) 2016-2025 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'test/unit'
require_relative 'test__helper'
require_relative 'fake_github'
require_relative '../objects/invitations/github_invitations'

# GithubInvitations test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2025 Yegor Bugayenko
# License:: MIT
class TestGithubInvitation < Test::Unit::TestCase
  def test_accepts_organization_invitations
    organizations = %w[github google microsoft zerocracy]
    github = FakeGithub.new(
      memberships: organizations.collect do |org|
        {
          'state' => %w[github zerocracy].include?(org) ? 'active' : 'pending',
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
    repositories.map { |repo| assert(github.repositories.include?(repo)) }
  end
end
