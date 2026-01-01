# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

#
# Storage that upgrades itself on load.
#
class UpgradedStorage
  def initialize(origin, version)
    @origin = origin
    @version = version
  end

  def load
    xml = @origin.load
    if xml.xpath('/*/@version')[0] != @version
      %w[remove-broken-issues add-namespace].each do |xsl|
        xml = Nokogiri::XSLT(
          File.read("assets/upgrades/#{xsl}.xsl")
        ).transform(xml)
      end
      save(xml)
    end
    xml
  end

  def save(xml)
    @origin.save(xml)
  end
end
