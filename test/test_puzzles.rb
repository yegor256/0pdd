# Copyright (c) 2016-2022 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'nokogiri'
require 'ostruct'
require 'test/unit'
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
# Copyright:: Copyright (c) 2016-2022 Yegor Bugayenko
# License:: MIT
class TestPuzzles < Test::Unit::TestCase
  def test_all_xml
    Dir.mktmpdir 'test' do |d|
      test_xml(d, 'simple.xml')
      test_xml(d, 'closes-one-puzzle.xml')
      test_xml(d, 'ignores-unknown-issues.xml')
      test_xml(d, 'submits-old-puzzles.xml')
      test_xml(d, 'submits-three-tickets.xml')
      test_xml(d, 'submits-ranked-puzzles.xml', ordered: true)
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
      assert(
        !after.xpath(xpath.text).empty?,
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
      assert(
        tickets.closed.include?(ticket.text),
        "Ticket #{ticket} was not closed: #{tickets.closed}"
      )
    end
    tickets.closed.each do |ticket|
      assert(
        !xml.xpath("/test/close[ticket='#{ticket}']").empty?,
        "Ticket #{ticket} was closed by mistake"
      )
    end
  end
end
