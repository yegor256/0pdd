# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../model/linear'

#
# Decorator of a Git repository that returns the XML snapshot with
# puzzles ranked by the ML model.
#
class RankingRepo
  def initialize(origin, storage)
    @origin = origin
    @storage = storage
  end

  def name
    @origin.name
  end

  def config
    @origin.config
  end

  # XML snapshot with puzzles reordered according to their ranks.
  def xml
    rank(@origin.xml)
  end

  private

  def rank(snapshot)
    puzzles = snapshot.xpath('/puzzles/puzzle')
    return snapshot if puzzles.empty?
    ranks = LinearModel.new(@origin.name, @storage).predict(
      puzzles.map { |p| p.element_children.to_h { |e| [e.name, e.text] } }
    )
    root = snapshot.xpath('/puzzles')[0]
    ranks.each { |i| root.add_child(puzzles[i]) }
    snapshot
  end
end
