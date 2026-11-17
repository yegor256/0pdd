# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'puzzles'
require_relative 'ranking_repo'

#
# Puzzles that are optionally ranked with the ML model.
#
# If +model: true+ is set in the YAML config of the repository, the
# puzzles are ranked with <tt>LinearModel</tt> right after they are
# joined with the storage, otherwise they are deployed as-is.
#
class MaybeRankedPuzzles < Puzzles
  def initialize(repo, storage, weights_storage = nil)
    super(repo, storage)
    @weights_storage = weights_storage
  end

  private

  # Ranks the puzzles, if the model is enabled in the config,
  # otherwise keeps their order.
  def rank(xml)
    return xml unless model?
    RankingRepo.new(@repo, @storage, @weights_storage).rank(xml)
  end

  def model?
    @repo.config && @repo.config['model'] == true
  end
end
