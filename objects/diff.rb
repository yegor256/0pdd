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
    @after.xpath('//puzzle/ticket/text()').map(&:to_s).uniq.each do |t|
      current = summary(@after, t)
      previous = summary(@before, t)
      next if previous == current
      next if current.empty?
      tickets.notify(t, "#{current}.")
    end
  end

  private

  def issues(xml, *xpath)
    xpath.map { |x| xml.xpath(x) }.flatten.map do |p|
      issue = p.xpath('issue')
      if issue.empty?
        "`#{p.xpath('id')}`"
      else
        "[##{issue[0].text}](#{issue[0]['href']})"
      end
    end.sort
  end

  def summary(xml, ticket)
    all = issues(
      xml,
      "//puzzle[ticket='#{ticket}']/children//puzzle",
      "//puzzle[ticket='#{ticket}']"
    )
    alive = issues(
      xml,
      "//puzzle[ticket='#{ticket}']/children//puzzle[@alive='true']",
      "//puzzle[ticket='#{ticket}' and @alive='true']"
    )
    if alive.empty?
      if all.empty?
        ''
      elsif all.length == 1
        "the only puzzle #{all[0]} is solved here"
      else
        "all #{all.length} puzzles are solved here: #{all.join(', ')}"
      end
    else
      solved = all - alive
      tail = solved.empty? ? '' : "; solved: #{solved.join(', ')}"
      if alive.length == 1
        "the puzzle #{alive[0]} is still not solved"
      else
        "#{alive.length} puzzles #{alive.join(', ')} are still not solved"
      end + tail
    end
  end
end
