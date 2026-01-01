# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'matrix'

#
# Zero vector class
#
class ZeroVector < Vector
  def normalize
    return self if zero?
    super
  end
end
