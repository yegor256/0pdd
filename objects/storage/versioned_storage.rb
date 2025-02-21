# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

#
# Storage that adds version to the XML when it gets saved.
#
class VersionedStorage
  def initialize(origin, version)
    @origin = origin
    @version = version
  end

  def load
    xml = @origin.load
    root = xml.xpath('/*')[0]
    unless root['date']
      root['date'] = '2016-12-08T12:00:49Z'
      root['version'] = '0.0.0'
    end
    xml
  end

  def save(xml)
    root = xml.xpath('/*')[0]
    root['date'] = Time.now.iso8601
    root['version'] = @version
    @origin.save(xml)
  end
end
