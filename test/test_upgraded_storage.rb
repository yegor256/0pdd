# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'test/unit'
require 'nokogiri'
require_relative 'test__helper'
require_relative 'fake_storage'
require_relative 'fake_log'
require_relative '../objects/storage/safe_storage'
require_relative '../objects/storage/upgraded_storage'
require_relative '../objects/storage/versioned_storage'

# UpgradedStorage test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2025 Yegor Bugayenko
# License:: MIT
class TestUpgradedStorage < Test::Unit::TestCase
  def test_safety_preserved
    fake = FakeStorage.new
    fake.save(Nokogiri::XML('<puzzles/>'))
    storage = UpgradedStorage.new(
      SafeStorage.new(VersionedStorage.new(fake, '0.0.5')),
      '0.0.5'
    )
    assert(!storage.load.xpath('/puzzles').empty?)
  end

  def test_removes_broken_issues
    storage = UpgradedStorage.new(FakeStorage.new, '0.0.1')
    storage.save(
      Nokogiri::XML(
        '<puzzles><puzzle><id>X1</id><issue>123</issue></puzzle>
        <puzzle><id>X2</id><issue/></puzzle><puzzles/>'
      )
    )
    assert(!storage.load.xpath('//puzzle[id="X1"]/issue').empty?)
    assert(storage.load.xpath('//puzzle[id="X2"]/issue').empty?)
  end

  def test_removes_broken_href
    storage = UpgradedStorage.new(FakeStorage.new, '0.0.2')
    storage.save(
      Nokogiri::XML(
        '<puzzles><puzzle><id>X1</id><issue href="#">123</issue></puzzle>
        <puzzle><id>X2</id><issue>123</issue></puzzle><puzzles/>'
      )
    )
    assert(!storage.load.xpath('//puzzle[id="X1"]/issue/@href').empty?)
    assert(storage.load.xpath('//puzzle[id="X2"]/issue/@href').empty?)
  end
end
