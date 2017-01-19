# encoding: utf-8
#
# Copyright (c) 2016-2017 Yegor Bugayenko
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
require_relative '../objects/git_repo'
require_relative '../objects/puzzles'
require_relative '../objects/safe_storage'

# Puzzles test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2016-2017 Yegor Bugayenko
# License:: MIT
class TestPuzzles < Test::Unit::TestCase
  def test_all_xml
    Dir.mktmpdir 'test' do |d|
      test_xml(d, 'simple.xml')
      test_xml(d, 'closes-one-puzzle.xml')
    end
  end

  def test_xml(dir, name)
    xml = File.open("test-assets/puzzles/#{name}") { |f| Nokogiri::XML(f) }
    storage = SafeStorage.new(
      FakeStorage.new(
        dir,
        Nokogiri.XML(xml.xpath('/test/before/puzzles')[0].to_s)
      )
    )
    repo = OpenStruct.new(
      xml: Nokogiri.XML(xml.xpath('/test/snapshot/puzzles')[0].to_s)
    )
    tickets = FakeTickets.new
    Puzzles.new(repo, storage).deploy(tickets)
    xml.xpath('/test/assertions/xpath/text()').each do |xpath|
      after = storage.load
      assert(
        !after.xpath(xpath.to_s).empty?,
        "#{xpath} not found in #{after}"
      )
    end
    xml.xpath('/test/submit/id/text()').each do |id|
      assert(
        tickets.submitted.include?(id.to_s),
        "puzzle #{id} was not submitted: #{tickets.submitted}"
      )
    end
    xml.xpath('/test/close/ticket/text()').each do |ticket|
      assert(
        tickets.closed.include?(ticket.to_s),
        "ticket #{ticket} was not closed: #{tickets.closed}"
      )
    end
  end

  private

  def fake_tickets
    Class.new do
      attr_reader :submitted, :closed
      def initialize
        @submitted = []
        @closed = []
      end

      def submit(puzzle)
        @submitted << puzzle.xpath('id').text
        '123'
      end

      def close(puzzle)
        @closed << puzzle.xpath('id').text
      end
    end.new
  end

  def fake_storage(dir, xml)
    storage = Class.new do
      def initialize(dir)
        @file = File.join(dir, 'storage.xml')
      end

      def load
        Nokogiri.XML(IO.read(@file))
      end

      def save(xml)
        IO.write(@file, xml.to_s)
      end
    end.new(dir)
    storage.save(xml)
    storage
  end
end
