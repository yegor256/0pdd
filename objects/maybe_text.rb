# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

#
# Maybe text
#
class MaybeText
  def initialize(text_if_present, maybe, exclude_if: false)
    @maybe = maybe
    @text = text_if_present
    @exclude_if = exclude_if
  end

  def to_s
    if @maybe.nil? || @maybe.empty? || @maybe == @exclude_if
      ''
    else
      @text
    end
  end
end
