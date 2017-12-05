# Copyright (c) 2016-2017 Yegor Bugayenko
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
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'octokit'

#
# Tickets in Github with tags.
# API: http://octokit.github.io/octokit.rb/method_list.html
#
class GithubTaggedTickets
  def initialize(repo, github, sources, tickets)
    @repo = repo
    @github = github
    @sources = sources
    @tickets = tickets
  end

  def submit(puzzle)
    done = @tickets.submit(puzzle)
    issue = done[:number]
    yaml = @sources.config
    if yaml['tags'] && yaml['tags'].is_a?(Array)
      tags = yaml['tags'].map(&:strip).map(&:downcase)
      labels = @github.labels(@repo).map { |json| json['name'] }
      needed = tags - labels
      begin
        needed.each { |t| @github.add_label(@repo, t, 'F74219') }
        @github.add_labels_to_an_issue(@repo, issue, tags)
      rescue Octokit::NotFound => e
        @github.add_comment(
          @repo, issue,
          "I can't create GitHub labels `#{needed.join('`, `')}`. \
Most likely I don't have necessary permissions to `#{@repo}` repository. \
Please, make sure @0pdd user is in the \
[list of collaborators](https://github.com/#{@repo}/settings/collaboration):\
\n\n```#{e.class.name}\n#{e.message}\n#{e.backtrace.join("\n")}\n```"
        )
      rescue Octokit::Error => e
        @github.add_comment(
          @repo, issue,
          "For some reason I wasn't able to add GitHub labels to this issue. \
Please, [submit a ticket](https://github.com/yegor256/0pdd/issues/new) \
to us with the text you see below:\
\n\n```#{e.class.name}\n#{e.message}\n#{e.backtrace.join("\n")}\n```"
        )
      end
    end
    done
  end

  def close(puzzle)
    @tickets.close(puzzle)
  end
end
