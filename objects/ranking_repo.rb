# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../model/linear'

#
# Ranking of the puzzles to be deployed.
#
# Ranks the puzzles of the XML document that <tt>Puzzles</tt> builds
# after the snapshot is joined with the storage: the puzzles that
# will be submitted are moved to the end of the document, in the
# order of their ranks. Puzzles that already have their issues stay
# where they are, since they are not submitted.
#
class RankingRepo
  def initialize(origin, storage, weights_storage = nil)
    @origin = origin
    @storage = storage
    @weights_storage = weights_storage
  end

  # Moves the puzzles to be submitted (alive, with no issue or an
  # unknown one) to the end of the XML document, in the order of
  # their ranks.
  def rank(xml)
    candidates = xml.xpath(
      "//puzzle[@alive='true' and (not(issue) or issue='unknown')]"
    )
    return xml if candidates.empty?
    ranks = LinearModel.new(@origin.name, @storage, @weights_storage).predict(
      candidates.map { |puzzle| puzzle.element_children.to_h { |e| [e.name, e.text] } }
    )
    puzzles = xml.xpath('/puzzles')[0]
    ranks.each { |i| puzzles << candidates[i].remove }
    xml
  end
end
