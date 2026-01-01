# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require 'ostruct'
require 'tmpdir'
require_relative 'test__helper'
require_relative 'fake_storage'
require_relative 'fake_tickets'
require_relative '../version'
require_relative '../objects/git_repo'
require_relative '../objects/puzzles'
require_relative '../objects/storage/safe_storage'
require_relative '../objects/storage/versioned_storage'

# Puzzles test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2026 Yegor Bugayenko
# License:: MIT
class TestPuzzles < Minitest::Test
  def test_all_xml
    Dir.mktmpdir 'test' do |d|
      test_xml(d, 'simple.xml')
      test_xml(d, 'closes-one-puzzle.xml')
      test_xml(d, 'ignores-unknown-issues.xml')
      test_xml(d, 'submits-old-puzzles.xml')
      test_xml(d, 'submits-three-tickets.xml')
      # test_xml(d, 'submits-ranked-puzzles.xml', ordered: true)
    end
  end

  def test_with_broken_tickets
    tickets = Object.new
    def tickets.submit(_)
      nil
    end
    xml = File.open('test-assets/puzzles/simple.xml') { |f| Nokogiri::XML(f) }
    Dir.mktmpdir 'test' do |dir|
      Puzzles.new(
        OpenStruct.new(
          xml: Nokogiri.XML(xml.xpath('/test/snapshot/puzzles')[0].to_s),
          config: {}
        ),
        FakeStorage.new(
          dir,
          Nokogiri.XML('<puzzles/>')
        )
      ).deploy(tickets)
    end
  end

  private

  def test_xml(dir, name, ordered: false)
    xml = File.open("test-assets/puzzles/#{name}") { |f| Nokogiri::XML(f) }
    storage = VersionedStorage.new(
      SafeStorage.new(
        FakeStorage.new(
          dir,
          Nokogiri.XML(xml.xpath('/test/before/puzzles')[0].to_s)
        )
      ),
      '0.0.1'
    )
    repo = OpenStruct.new(
      xml: Nokogiri.XML(xml.xpath('/test/snapshot/puzzles')[0].to_s),
      config: {}
    )
    tickets = FakeTickets.new
    Puzzles.new(repo, storage).deploy(tickets)
    xml.xpath('/test/assertions/xpath/text()').each do |xpath|
      after = storage.load
      refute_empty(
        after.xpath(xpath.text),
        "#{xpath} not found in #{after}"
      )
    end
    xml.xpath('/test/submit/ticket/text()').each_with_index do |id, idx|
      submitted = ordered ? tickets.submitted[idx] == id.text : tickets.submitted.include?(id.text)
      assert(
        submitted,
        "Puzzle #{id} was not submitted: #{tickets.submitted}"
      )
    end
    xml.xpath('/test/close/ticket/text()').each do |ticket|
      assert_includes(
        tickets.closed, ticket.text,
        "Ticket #{ticket} was not closed: #{tickets.closed}"
      )
    end
    tickets.closed.each do |ticket|
      refute_empty(
        xml.xpath("/test/close[ticket='#{ticket}']"),
        "Ticket #{ticket} was closed by mistake"
      )
    end
  end
end
