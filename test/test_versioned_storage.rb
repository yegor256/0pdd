# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'test/unit'
require 'nokogiri'
require_relative 'test__helper'
require_relative 'fake_storage'
require_relative 'fake_log'
require_relative '../objects/storage/versioned_storage'

# VersionedStorage test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2025 Yegor Bugayenko
# License:: MIT
class TestVersionedStorage < Test::Unit::TestCase
  def test_xml_versioning
    version = '0.0.1'
    storage = VersionedStorage.new(FakeStorage.new, version)
    storage.save(Nokogiri::XML('<test>hello</test>'))
    assert_equal(version, storage.load.xpath('/test/@version')[0].text)
  end
end
