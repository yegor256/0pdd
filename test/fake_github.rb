# Copyright (c) 2016-2018 Yegor Bugayenko
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

class FakeGithub
  def initialize(options = {})
    @memberships = if options[:memberships]
      options[:memberships]
    else
      [
        {
          'state' => 'pending',
          'organization' => {
            'login' => 'github'
          }
        }, {
          'state' => 'pending',
          'organization' => {
            'login' => 'zerocracy'
          }
        }
      ]
    end
    @invitations = if options[:invitations]
      options[:invitations]
    else
      [
        {
          'id' => 1001,
          'repository' => {
            'name' => 'yegor256/0pdd'
          }
        }, {
          'id' => 1023,
          'repository' => {
            'name' => 'yegor256/sixnines'
          }
        }
      ]
    end
    @repositories = options[:repositories] ? options[:repositories] : []
  end

  def issue(_, _)
    { 'state' => 'open' }
  end

  def close_issue(_, _)
    # nothing to do here
  end

  def create_issue(_, _, _)
    { 'number' => 555 }
  end

  def add_comment(_, _, _)
    # nothing to do here
  end

  def user(_login)
    { email: 'foobar@example.com' }
  end

  def rate_limit
    limit = Object.new

    def limit.remaining
      100
    end
    limit
  end

  def list_commits(_)
    [{ 'sha' => '123456' }]
  end

  def update_organization_membership(org, options = {})
    return unless options['state']
    @memberships.find do |m|
      m['organization']['login'] == org
    end['state'] = options['state']
  end

  def organization_memberships(options = {})
    if options['state']
      @memberships.find_all { |m| m['state'] == options['state'] }
    else
      @memberships
    end
  end

  def user_repository_invitations(_options = {})
    @invitations
  end

  def accept_repository_invitation(id, _options = {})
    invitation = @invitations.find { |i| i['id'] == id }
    return false if invitation.nil?
    @repositories = @repositories.push(invitation['repository']['name'])
    true
  end

  def repositories(user = nil, _options = {})
    return @repositories unless user
  end
end
