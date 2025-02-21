# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'test/unit'
require_relative 'test__helper'
require_relative 'fake_storage'
require_relative '../objects/storage/cached_storage'

# CachedStorage test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2025 Yegor Bugayenko
# License:: MIT
class TestCachedStorage < Test::Unit::TestCase
  def test_simple_xml_loading
    Dir.mktmpdir do |dir|
      storage = CachedStorage.new(FakeStorage.new, File.join(dir, 'a/b/z.xml'))
      storage.save(Nokogiri::XML('<test>hello</test>'))
      assert_equal('hello', storage.load.xpath('/test/text()')[0].text)
    end
  end
end
