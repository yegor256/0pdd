# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

#
# Thread-safe storage.
#
class SyncStorage
  def initialize(origin)
    @origin = origin
    @mutex = Mutex.new
  end

  def load
    @mutex.synchronize { @origin.load }
  end

  def save(xml)
    @mutex.synchronize { @origin.save(xml) }
  end
end
