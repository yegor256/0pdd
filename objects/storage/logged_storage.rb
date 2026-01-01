# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

#
# Storage that is logged.
#
class LoggedStorage
  def initialize(origin, log)
    @origin = origin
    @log = log
  end

  def load
    @origin.load
  end

  def save(xml)
    @origin.save(xml)
    @log.put(
      "save-#{Time.now.to_i}",
      "Saved XML, puzzles:#{xml.xpath('//puzzle[@alive="true"]').size}/\
#{xml.xpath('//puzzle').size}, chars:#{xml.to_s.length}, \
date:#{xml.xpath('/*/@date')[0].text}, \
version:#{xml.xpath('/*/@version')[0].text}"
    )
  end
end
