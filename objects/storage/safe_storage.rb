# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'

#
# Safe, XSD validated, storage.
#
class SafeStorage
  def initialize(origin)
    @origin = origin
    @xsd = Nokogiri::XML::Schema(File.read('assets/xsd/puzzles.xsd'))
  end

  def load
    @origin.load
  end

  def save(xml)
    @origin.save(valid(xml))
  end

  private

  def valid(xml)
    errors = @xsd.validate(xml).each(&:message)
    raise "XML has #{errors.length} errors\nw#{errors.join("\n")}\n#{xml}" unless errors.empty?
    xml
  end
end
