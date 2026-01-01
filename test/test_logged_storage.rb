# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative 'fake_storage'
require_relative 'fake_log'
require_relative '../objects/storage/logged_storage'
require_relative '../objects/storage/versioned_storage'

# LoggedStorage test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2026 Yegor Bugayenko
# License:: MIT
class TestLoggedStorage < Minitest::Test
  def test_simple_xml_saving
    storage = LoggedStorage.new(
      VersionedStorage.new(FakeStorage.new, '0.0.1'), FakeLog.new
    )
    storage.save(Nokogiri::XML('<test>hello</test>'))
    assert_equal('hello', storage.load.xpath('/test/text()')[0].text)
  end
end
