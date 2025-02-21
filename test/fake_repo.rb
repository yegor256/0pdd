# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'tempfile'

class FakeRepo
  attr_reader :name, :config

  def initialize(options = {})
    @name = options[:name] || 'GITHUB'
    @config = options[:config] || {}
  end

  def lock
    Tempfile.new('0pdd-lock')
  end

  def xml
    Nokogiri::XML('<puzzles date="2016-12-10T16:26:36Z"/>')
  end

  def push
    # nothing here
  end
end
