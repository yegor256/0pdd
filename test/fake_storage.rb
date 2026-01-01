# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'tempfile'

class FakeStorage
  def initialize(
    dir = Dir.mktmpdir,
    xml = '<puzzles date="2016-12-10T16:26:36Z" version="0.1"/>'
  )
    @file = File.join(dir, 'storage.xml')
    save(xml)
  end

  def load
    Nokogiri.XML(File.read(@file))
  end

  def save(xml)
    File.write(@file, xml.to_s)
  end
end
