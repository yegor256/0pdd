# Copyright (c) 2016-2022 Yegor Bugayenko
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

require 'json'
require 'crack'
require 'nokogiri'
require_relative '../model/linear'

#
# Puzzles in XML/S3
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
  # elements are added as <extra> elements. They later inside the
  # method join() will be placed to the right positions and will
  # either replace existing ones of will become new puzzles.
  def join(before, snapshot)
    after = Nokogiri::XML(before.to_s)
    target = after.xpath('/puzzles')[0]
    snapshot.xpath('//puzzle').each do |p|
      p.name = 'extra'
      target.add_child(p)
    end
    after
  end

  # Merge <extra> elements with <puzzle> elements in the XML. Some
  # extras will be simply deleted, while others will become new
  # puzzles.
  def group(xml)
    Nokogiri::XSLT(File.read('assets/xsl/group.xsl')).transform(
      Nokogiri::XSLT(File.read('assets/xsl/join.xsl')).transform(xml)
    )
  end

  # Take some puzzles from the XML and either close their tickets in GitHub
  # or create new tickets.
  def expose(xml, tickets)
    close(xml, tickets)
    skip_model = xml.xpath('/puzzles[@model="true"]').empty?
    if skip_model
      submit(xml, tickets)
    else
      submit_ranked(xml, tickets)
    end
  end

  def close(xml, tickets)
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
      puzzle.search('issue')[0]['closed'] = Time.now.iso8601 if tickets.close(puzzle)
      save(xml)
    end
  end

  def submit(xml, tickets)
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

  # Reads the list of all puzzles from the XML in the storage and then
  # sorts them in the right order, in which they should be present in the
  # backlog.
  def rank(puzzles)
    LinearModel.new(@repo.name, @storage).predict(
      puzzles.map { |puzzle| JSON.parse(Crack::XML.parse(puzzle.to_s).to_json)['puzzle'] }
    )
  end

  def submit_ranked(xml, tickets)
    seen = []
    unique_puzzles = []
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
      unique_puzzles.append(puzzle.dup)
      seen << id
    end
    submitted = 0
    ranked_idx = rank(unique_puzzles)
    Kernel.loop do
      puzzles = xml.xpath(
        '//puzzle[@alive="true" and (not(issue) or issue="unknown")]'
      )
      break if puzzles.empty? || ranked_idx.empty? || submitted >= @threshold
      next_idx = ranked_idx.shift
      puzzle = puzzles.find { |p| p.xpath('id')[0].text == unique_puzzles[next_idx].xpath('id')[0].text }
      issue = tickets.submit(puzzle)
      next if issue.nil?
      puzzle.search('issue').remove
      puzzle.add_child(
        "<issue href='#{issue[:href]}' model='#{next_idx}'>#{issue[:number]}</issue>"
      )
      save(xml)
      submitted += 1
    end
  end
end
