# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

class FakeTickets
  attr_reader :submitted, :closed

  def initialize
    @submitted = []
    @closed = []
  end

  def submit(puzzle)
    @submitted << puzzle.xpath('id')[0].text
    { number: '123', href: 'http://0pdd.com' }
  end

  def close(puzzle)
    @closed << puzzle.xpath('id')[0].text
    true
  end
end
