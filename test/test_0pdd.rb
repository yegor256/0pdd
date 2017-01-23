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

ENV['RACK_ENV'] = 'test'

require 'test/unit'
require 'rack/test'
require_relative '../0pdd'

class AppTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_renders_version
    get('/version')
    assert(last_response.ok?)
  end

  def test_robots_txt
    get('/robots.txt')
    assert(last_response.ok?)
  end

  def test_it_renders_home_page
    get('/')
    assert(last_response.ok?)
    assert(last_response.body.include?('Hello, world'))
  end

  def test_renders_page_not_found
    get('/the-url-that-is-absent')
    assert(last_response.status == 404)
  end

  def test_it_understands_push_from_github
    post(
      '/hook/github',
      '{"repository":{"full_name":"yegor256/pdd"}, "ref":"refs/heads/master"}',
      'CONTENT_TYPE' => 'application/json'
    )
    assert(last_response.ok?)
    assert(last_response.body.include?('thanks'))
  end

  def test_renders_html_puzzles
    get('/p?name=yegor256/pdd')
    assert(last_response.ok?)
    html = last_response.body
    assert(
      html.include?('<html') &&
        html.include?('<title>'),
      "broken HTML: #{html}"
    )
  end

  def test_renders_svg_puzzles
    get('/svg?name=yegor256/pdd')
    assert(last_response.ok?)
    svg = last_response.body
    IO.write('/tmp/0pdd-button.svg', svg)
    assert(
      svg.include?('<svg '),
      "broken SVG: #{svg}"
    )
  end

  def test_renders_xml_puzzles
    get('/xml?name=yegor256/pdd')
    assert(last_response.ok?)
    xml = last_response.body
    assert(
      xml.include?('<puzzles '),
      "broken XML: #{xml}"
    )
  end
end
