# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'tmpdir'
require_relative 'test__helper'
require_relative '../objects/log'

class FakeDynamoLog
  def initialize
    @items = {}
  end

  def put_item(table_name:, item:)
    @items[item['repo']] ||= []
    @items[item['repo']] << item.merge('table' => table_name)
  end

  def query(table_name:, expression_attribute_values:, **_options)
    repo = expression_attribute_values.fetch(':r')
    tag = expression_attribute_values.fetch(':t')
    items = @items.fetch(repo, []).select do |item|
      item['table'] == table_name && item['tag'] == tag
    end
    OpenStruct.new(items: items)
  end
end

# Log test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2026 Yegor Bugayenko
# License:: MIT
class TestLog < Minitest::Test
  def test_put_and_check
    log = Log.new(FakeDynamoLog.new, 'yegor256/0pdd')
    tag = 'some-tag'
    log.put(tag, 'some text here')
    assert(log.exists(tag))
  end

  def test_separates_same_repo_between_vcs
    dynamo = FakeDynamoLog.new
    repo = 'yegor256/0pdd'
    tag = 'same-tag'
    github = Log.new(dynamo, repo, 'github')
    gitlab = Log.new(dynamo, repo, 'gitlab')
    github.put(tag, 'github text')
    refute(gitlab.exists(tag))
    gitlab.put(tag, 'gitlab text')
    assert(gitlab.exists(tag))
    refute_equal(github.get(tag)['repo'], gitlab.get(tag)['repo'])
  end

  def test_rejects_unknown_vcs
    assert_raises(RuntimeError) do
      Log.new(FakeDynamoLog.new, 'yegor256/0pdd', 'unknown')
    end
  end
end
