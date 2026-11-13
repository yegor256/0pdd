# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'puzzles'
require_relative 'ranking_repo'

#
# Decorator of +Puzzles+ that optionally ranks them with the ML model.
# If +model: true+ is set in the YAML config of the repository, puzzles
# are ranked before deployment, otherwise they are deployed as-is.
#
class MaybeRankedPuzzles
  def initialize(repo, storage)
    @repo = repo
    @storage = storage
  end

  # Rank puzzles first, if the model is enabled in the config,
  # and then deploy them.
  def deploy(tickets)
    Puzzles.new(deployable, @storage).deploy(tickets)
  end

  private

  def deployable
    model? ? RankingRepo.new(@repo, @storage) : @repo
  end

  def model?
    @repo.config['model'] == true
  end
end
