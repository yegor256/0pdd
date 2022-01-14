# Copyright (c) 2016-2021 Yegor Bugayenko
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

require 'mail'
require_relative 'puzzles'
require_relative 'diff'

#
# One job.
#
class Job
  def initialize(vcs, storage, tickets)
    @vcs = vcs
    @storage = storage
    @tickets = tickets
    @initial_puzzles = nil
  end

  def proceed
    @vcs.repo.push
    @initial_puzzles = @storage.load
    Puzzles.new(@vcs.repo, @storage).deploy(@tickets)
    return if opts.include?('on-scope')
    Diff.new(@initial_puzzles, @storage.load).notify(@tickets)
  rescue Octokit::ClientError, Gitlab::Error => e
    # TODO: this is a temporary solution, we should use a logger
    save(@initial_puzzles) if @initial_puzzles
    throw e
  end

  private

  def opts
    array = @vcs.repo.config.dig('alerts', 'suppress')
    array.nil? || !array.is_a?(Array) ? [] : array
  end
end
