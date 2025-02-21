# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'test/unit'
require 'tmpdir'
require_relative 'test__helper'
require_relative '../objects/log'
require_relative '../objects/dynamo'

# Log test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2025 Yegor Bugayenko
# License:: MIT
class TestLog < Test::Unit::TestCase
  def test_put_and_check
    log = Log.new(Dynamo.new.aws, 'yegor256/0pdd')
    tag = 'some-tag'
    log.put(tag, 'some text here')
    assert(log.exists(tag))
  end
end
