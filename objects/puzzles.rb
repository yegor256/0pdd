# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'json'
require 'crack'
require 'nokogiri'
require_relative '../model/linear'

#
# Puzzles in XML/S3
# @todo #532:60min Implement a decorator for optional model configuration load.
#  Let's implement a class that decorates `Puzzles` and
#  based on presence of `model: true` attribute in YAML config, decides
#  whether the puzzles should be ranked or not.
#  Don't forget to remove this puzzle.
#
class Puzzles
  def initialize(repo, storage)
    @repo = repo
    @storage = storage
    t = repo.config && repo.config['threshold'].to_i
    @threshold = t.positive? && t < 256 ? t : 256
  end

  # Find out which puzzles deservers to become new tickets and submit
  # them to the repository (GitHub, for example). Also, find out which
  # puzzles are no longer active and remove them from GitHub.
  def deploy(tickets)
    xml = join(@storage.load, @repo.xml)
    xml = rank(joined(xml))
    xml = group(xml)
    save(xml)
    expose(xml, tickets)
  end

  private

  # Save new XML into the storage, replacing the existing one.
  def save(xml)
    @storage.save(xml)
  end

  # Join existing XML with the snapshot just arrived from PDD
  # toolkit output after the analysis of the code base. New <puzzle>
  # elements are added as <extra> elements. They later, in joined(),
  # will be placed to the right positions and will either replace
  # existing ones or will become new puzzles.
  def join(before, snapshot)
    after = Nokogiri::XML(before.to_s)
    target = after.xpath('/puzzles')[0]
    snapshot.xpath('//puzzle').each do |p|
      p.name = 'extra'
      target.add_child(p)
    end
    after
  end

  # Merge <extra> elements with <puzzle> elements in the XML
  # (join.xsl). Some extras will be simply deleted, while others
  # will become new puzzles. All puzzles in the resulting document
  # are flat: they stay on the top level and receive the +alive+
  # attribute and the +issue+ element.
  def joined(xml)
    Nokogiri::XSLT(File.read('assets/xsl/join.xsl')).transform(xml)
  end

  # Nest child puzzles under their parents (group.xsl).
  def group(xml)
    Nokogiri::XSLT(File.read('assets/xsl/group.xsl')).transform(xml)
  end

  # Ranks the puzzles that will be submitted, after the snapshot is
  # joined with the storage. Does nothing by default: puzzles keep
  # their order. Ranking extensions of +Puzzles+ override this
  # method, see RankedPuzzles.
  def rank(xml)
    xml
  end

  # Take some puzzles from the XML and either close their tickets in GitHub
  # or create new tickets.
  def expose(xml, tickets)
    seen = []
    Kernel.loop do
      puzzles = xml.xpath(
        [
          '//puzzle[@alive="false" and issue',
          'and issue != "unknown" and not(issue/@closed)',
          seen.map { |i| "and id != '#{i}'" }.join(' '),
          ']'
        ].join(' ')
      )
      break if puzzles.empty?
      puzzle = puzzles[0]
      seen << puzzle.xpath('id')[0].text
      puzzle.search('issue')[0]['closed'] = Time.now.iso8601 if tickets.close(puzzle)
      save(xml)
    end
    seen = []
    Kernel.loop do
      puzzles = xml.xpath(
        [
          '//puzzle[@alive="true" and (not(issue) or issue="unknown")',
          seen.map { |i| "and id != '#{i}'" }.join(' '),
          ']'
        ].join(' ')
      )
      break if puzzles.empty?
      puzzle = puzzles[0]
      id = puzzle.xpath('id')[0].text
      seen << id
      issue = tickets.submit(puzzle)
      next if issue.nil?
      puzzle.search('issue').remove
      puzzle.add_child(
        "<issue href='#{issue[:href]}'>#{issue[:number]}</issue>"
      )
      save(xml)
    end
  end
end
