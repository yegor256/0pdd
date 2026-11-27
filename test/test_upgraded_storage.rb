# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'fileutils'
require 'tempfile'
require_relative 'test__helper'
require_relative 'fake_storage'
require_relative 'fake_log'
require_relative '../objects/storage/cached_storage'
require_relative '../objects/storage/once_storage'
require_relative '../objects/storage/safe_storage'
require_relative '../objects/storage/sync_storage'
require_relative '../objects/storage/upgraded_storage'
require_relative '../objects/storage/versioned_storage'

# UpgradedStorage test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2026 Yegor Bugayenko
# License:: MIT
class TestUpgradedStorage < Minitest::Test
  def test_safety_preserved
    fake = FakeStorage.new
    fake.save(Nokogiri::XML('<puzzles/>'))
    storage = UpgradedStorage.new(
      SafeStorage.new(VersionedStorage.new(fake, '0.0.5')),
      '0.0.5'
    )
    refute_empty(storage.load.xpath('/puzzles'))
  end

  def test_removes_broken_issues
    storage = UpgradedStorage.new(FakeStorage.new, '0.0.1')
    storage.save(
      Nokogiri::XML(
        '<puzzles><puzzle><id>X1</id><issue>123</issue></puzzle>
        <puzzle><id>X2</id><issue/></puzzle><puzzles/>'
      )
    )
    refute_empty(storage.load.xpath('//puzzle[id="X1"]/issue'))
    assert_empty(storage.load.xpath('//puzzle[id="X2"]/issue'))
  end

  def test_removes_broken_href
    storage = UpgradedStorage.new(FakeStorage.new, '0.0.2')
    storage.save(
      Nokogiri::XML(
        '<puzzles><puzzle><id>X1</id><issue href="#">123</issue></puzzle>
        <puzzle><id>X2</id><issue>123</issue></puzzle><puzzles/>'
      )
    )
    refute_empty(storage.load.xpath('//puzzle[id="X1"]/issue/@href'))
    assert_empty(storage.load.xpath('//puzzle[id="X2"]/issue/@href'))
  end

  def test_empty_stored_document_treated_as_new
    storage = UpgradedStorage.new(
      FakeStorage.new(Dir.mktmpdir, '<?xml version="1.0"?>'),
      '0.0.5'
    )
    refute_nil(storage.load.xpath('/puzzles')[0])
  end

  def test_empty_document_survives_full_storage_stack
    storage = SyncStorage.new(
      UpgradedStorage.new(
        SafeStorage.new(
          OnceStorage.new(
            CachedStorage.new(
              VersionedStorage.new(
                FakeStorage.new(Dir.mktmpdir, '<?xml version="1.0"?>'),
                '0.0.5'
              ),
              File.join(Dir.mktmpdir, 'cache')
            )
          )
        ),
        '0.0.5'
      )
    )
    refute_empty(storage.load.xpath('/puzzles'))
  end

  def test_rootless_cache_does_not_hide_healthy_origin
    dir = Dir.mktmpdir
    fake = FakeStorage.new(
      dir,
      '<puzzles date="2016-12-10T16:26:36Z" version="0.0.5">' \
      '<puzzle alive="true"><id>1-abcdef12</id><issue>123</issue>' \
      '<body>Do something</body><lines>1-2</lines><file>a/b.rb</file>' \
      '<estimate>30</estimate><ticket>1</ticket><role>DEV</role>' \
      '<author>user</author><email>user@example.com</email>' \
      '<time>2016-12-10T16:26:36Z</time></puzzle></puzzles>'
    )
    file = File.join(dir, 'cache')
    FileUtils.mkdir_p(File.dirname(file))
    File.write(file, '<?xml version="1.0"?>')
    storage = SyncStorage.new(
      UpgradedStorage.new(
        SafeStorage.new(
          OnceStorage.new(
            CachedStorage.new(VersionedStorage.new(fake, '0.0.5'), file)
          )
        ),
        '0.0.5'
      )
    )
    refute_empty(storage.load.xpath('//puzzle[id="1-abcdef12"]/issue'))
    assert_equal('123', storage.load.xpath('//puzzle[id="1-abcdef12"]/issue').text)
  end

  def test_empty_cached_document_survives_full_storage_stack
    file = File.join(Dir.mktmpdir, 'cache')
    FileUtils.mkdir_p(File.dirname(file))
    File.write(file, '<?xml version="1.0"?>')
    storage = SyncStorage.new(
      UpgradedStorage.new(
        SafeStorage.new(
          OnceStorage.new(
            CachedStorage.new(
              VersionedStorage.new(FakeStorage.new, '0.0.5'),
              file
            )
          )
        ),
        '0.0.5'
      )
    )
    refute_empty(storage.load.xpath('/puzzles'))
  end
end
