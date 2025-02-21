# SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'test/unit'
require 'mocha/test_unit'
require_relative 'test__helper'
require_relative '../objects/tickets/sentry_tickets'

# SentryTickets test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2025 Yegor Bugayenko
# License:: MIT
class TestSentryTickets < Test::Unit::TestCase
  def test_exception_catching_on_submit
    tickets = Object.new
    def tickets.submit(_)
      raise 'submit failure'
    end
    Mail::Message.any_instance.stubs(:deliver!)
    assert_raise do
      SentryTickets.new(tickets).submit(0)
    end
  end

  def test_exception_catching_on_close
    tickets = Object.new
    def tickets.close(_)
      raise 'close failure'
    end
    Mail::Message.any_instance.stubs(:deliver!)
    assert_raise do
      SentryTickets.new(tickets).close(0)
    end
  end
end
