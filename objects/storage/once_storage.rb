# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

#
# Saves only once, if the content wasn't really changed.
#
class OnceStorage
  def initialize(origin)
    @origin = origin
  end

  def load
    @origin.load
  end

  def save(xml)
    @origin.save(xml) if load.to_s != xml.to_s
  end
end
