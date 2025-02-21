# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

#
# FakeWeightsStorage
#
class FakeWeightsStorage
  def initialize(
    repo,
    dir = Dir.mktmpdir
  )
    @file = File.join(dir, "#{repo}.marshal")
  end

  def load
    # rubocop:disable Security/MarshalLoad
    Marshal.load(File.read(@file)) if File.exist?(@file)
    # rubocop:enable Security/MarshalLoad
  end

  def save(weights)
    File.write(@file, Marshal.dump(weights))
  end
end
