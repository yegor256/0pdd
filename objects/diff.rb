# Copyright (c) 2016-2018 Yegor Bugayenko
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

require 'nokogiri'

#
# Diff.
#
class Diff
  def initialize(before, after)
    @before = before
    @after = after
  end

  def notify(tickets)
    @after.xpath('//puzzle[issue]').each do |p|
      id = p.xpath('id/text()')[0]
      current = summary(p)
      old = @before.xpath("//puzzle[id='#{id}']")
      previous = old.empty? ? '' : summary(old[0])
      next if previous == current
      next if current.empty?
      tickets.notify(p.xpath('issue/text()')[0], current)
    end
    @after.xpath('/puzzles/puzzle[ticket]').each do |p|
      id = p.xpath('id/text()')[0]
      current = summary(p, true)
      old = @before.xpath("//puzzle[id='#{id}']")
      previous = old.empty? ? '' : summary(old[0], true)
      next if previous == current
      next if current.empty?
      tickets.notify(p.xpath('ticket/text()')[0], current)
    end
  end

  private

  def issues(puzzle, xpath)
    puzzle.xpath(xpath).map do |p|
      "[#{p.xpath('issue/text()')[0]}](#{p.xpath('issue/@href')})"
    end
  end

  def summary(puzzle, itself = false)
    all = issues(puzzle, 'children//puzzle')
    all += issues(puzzle, 'self::node()') if itself
    alive = issues(puzzle, 'children//puzzle[@alive="true" and issue]')
    alive += issues(puzzle, 'self::node()[@alive="true" and issue]') if itself
    if alive.empty?
      if all.empty?
        ''
      elsif all.length == 1
        "the puzzle #{all[0]} is solved"
      else
        "all #{all.length} puzzles are solved: #{all.join(', ')}"
      end
    elsif alive.length == 1
      "the puzzle #{alive[0]} is still not solved"
    else
      "these puzzles are still not solved: #{alive.join(', ')}"
    end
  end
end
