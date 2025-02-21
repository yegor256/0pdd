# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

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
        number = issue[0].text
        link = issue[0]['href']
        number = link.split('/')[-1] if link && number == 'unknown'
        "[##{number}](#{link})"
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
