# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require_relative 'fake_storage'
require_relative '../objects/storage/once_storage'

# OnceStorage test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2025 Yegor Bugayenko
# License:: MIT
class TestOnceStorage < Minitest::Test
  def test_never_saves_duplicates
    origin = TestStorage.new
    storage = OnceStorage.new(origin)
    storage.save(Nokogiri::XML('<test>hello</test>'))
    assert_equal(0, origin.count)
  end

  def test_saves_only_once
    origin = TestStorage.new
    storage = OnceStorage.new(origin)
    storage.save(Nokogiri::XML('<test>bye</test>'))
    assert_equal(1, origin.count)
  end

  class TestStorage
    attr_reader :count

    def initialize
      @count = 0
    end

    def load
      Nokogiri::XML('<test>hello</test>')
    end

    def save(_)
      @count += 1
    end
  end
end
