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
    max_issues = repo.config && repo.config['max_issues'].to_i
    @max_issues = max_issues.positive? && max_issues < 100 ? max_issues : 100
  end

  def deploy(tickets)
    expose(
      save(
        group(
          join(@storage.load, @repo.xml)
        )
      ),
      tickets
    )
  end

  private

  def save(xml)
    @storage.save(xml)
    xml
  end

  def join(before, snapshot)
    after = Nokogiri::XML(before.to_s)
    target = after.xpath('/puzzles')[0]
    snapshot.xpath('//puzzle').each do |p|
      p.name = 'extra'
      target.add_child(p)
    end
    after
  end

  def group(xml)
    Nokogiri::XSLT(File.read('assets/xsl/group.xsl')).transform(
      Nokogiri::XSLT(File.read('assets/xsl/join.xsl')).transform(xml)
    )
  end

  def rank(puzzles)
    puzzles = puzzles.map { |puzzle| JSON.parse(Crack::XML.parse(puzzle.to_s).to_json)['puzzle'] }
    LinearModel.new(@repo.name, @storage).predict(puzzles)
  end

  def expose(xml, tickets)
    seen = []
    Kernel.loop do
      puzzles = xml.xpath(
        '//puzzle[@alive="false" and issue
        and issue != "unknown" and not(issue/@closed)' +
        seen.map { |i| "and id != '#{i}'" }.join(' ') + ']'
      )
      break if puzzles.empty?
      puzzle = puzzles[0]
      puzzle.search('issue')[0]['closed'] = Time.now.iso8601 if tickets.close(puzzle)
      save(xml)
    end
    seen = []
    unique_puzzles = []
    Kernel.loop do
      puzzles = xml.xpath(
        '//puzzle[@alive="true" and (not(issue) or issue="unknown")' +
        seen.map { |i| "and id != '#{i}'" }.join(' ') + ']'
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
      break if puzzles.empty? || ranked_idx.empty? || submitted >= @max_issues
      puzzle = puzzles.find { |p| p.xpath('id')[0].text == unique_puzzles[ranked_idx.shift].xpath('id')[0].text }
      issue = tickets.submit(puzzle)
      next if issue.nil?
      puzzle.search('issue').remove
      puzzle.add_child(
        "<issue href='#{issue[:href]}'>#{issue[:number]}</issue>"
      )
      save(xml)
      submitted += 1
    end
  end
end
