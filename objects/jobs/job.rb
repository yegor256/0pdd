# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'mail'
require_relative '../diff'
require_relative '../puzzles'

#
# One job.
#
class Job
  def initialize(vcs, storage, tickets)
    @vcs = vcs
    @storage = storage
    @tickets = tickets
  end

  def proceed
    @vcs.repo.push
    before = @storage.load
    Puzzles.new(@vcs.repo, @storage).deploy(@tickets)
    return if opts.include?('on-scope')
    Diff.new(before, @storage.load).notify(@tickets)
  end

  private

  def opts
    array = @vcs.repo.config.dig('alerts', 'suppress')
    array.nil? || !array.is_a?(Array) ? [] : array
  end
end
