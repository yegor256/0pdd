# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'mail'
require_relative 'test__helper'
require_relative '../objects/tickets/sentry_tickets'

# SentryTickets test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2026 Yegor Bugayenko
# License:: MIT
class TestSentryTickets < Minitest::Test
  def test_exception_catching_on_submit
    tickets = Object.new
    def tickets.submit(_)
      raise 'submit failure'
    end
    assert_raises(StandardError) do
      SentryTickets.new(tickets).submit(0)
    end
  end

  def test_exception_catching_on_close
    tickets = Object.new
    def tickets.close(_)
      raise 'close failure'
    end
    assert_raises(StandardError) do
      SentryTickets.new(tickets).close(0)
    end
  end
end
