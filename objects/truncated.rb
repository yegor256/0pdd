# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

#
# Truncated text.
#
class Truncated
  def initialize(text, max = 40, tail = '...')
    @text = text
    @max = max
    @tail = tail
  end

  def to_s
    clean = @text.gsub(/\s+/, ' ').strip
    if @max < clean.length
      limit = @max - @tail.length
      stop = clean.rindex(' ', limit) || 0
      "#{clean[0...stop]}#{@tail}"
    else
      clean
    end
  end
end
