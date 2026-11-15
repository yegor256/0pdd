# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../model/linear'
require_relative 'puzzles'

#
# Ranked puzzles.
#
# A decorator of <tt>Puzzles</tt> that ranks the puzzles with the
# <tt>LinearModel</tt> right after they are joined with the storage:
# the puzzles that will be submitted are reordered according to their
# ranks, before the document is saved and exposed to tickets. Puzzles
# that already have their issues stay where they are, since they are
# not submitted.
#
class RankedPuzzles < Puzzles
  def initialize(repo, storage, weights_storage = nil)
    super(repo, storage)
    @weights_storage = weights_storage
  end

  private

  # Moves the puzzles to be submitted (alive, with no issue or an
  # unknown one) to the end of the document, in the order of their
  # ranks.
  def rank(xml)
    candidates = xml.xpath(
      "//puzzle[@alive='true' and (not(issue) or issue='unknown')]"
    )
    return xml if candidates.empty?
    puzzles = xml.xpath('/puzzles')[0]
    ranks = LinearModel.new(@repo.name, @storage, @weights_storage).predict(
      candidates.map { |puzzle| puzzle.element_children.to_h { |e| [e.name, e.text] } }
    )
    ranks.each { |i| puzzles << candidates[i].remove }
    xml
  end
end
