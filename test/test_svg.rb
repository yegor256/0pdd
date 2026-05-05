# SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'nokogiri'
require_relative 'test__helper'

# SVG badge test.
class TestSvg < Minitest::Test
  XSL = Nokogiri::XSLT(File.read(File.expand_path('../assets/xsl/svg.xsl', __dir__)))

  def render(alive:, dead: 0)
    body = ('<puzzle alive="true"/>' * alive) + ('<puzzle alive="false"/>' * dead)
    XSL.transform(Nokogiri::XML("<puzzles>#{body}</puzzles>")).to_s
  end

  def count_text(svg)
    Nokogiri::XML(svg)
      .xpath('//*[local-name()="text" and @text-anchor="end"]')
      .first
      .text
  end

  def badge_width(svg)
    Nokogiri::XML(svg).root['width'].to_f
  end

  def test_renders_small_count
    svg = render(alive: 5, dead: 2)
    assert_equal('5/7', count_text(svg))
    refute_includes(svg, '99+')
  end

  def test_renders_count_when_above_threshold
    svg = render(alive: 150, dead: 50)
    refute_includes(svg, '99+', "badge must show real numbers, got: #{svg}")
    assert_equal('150/200', count_text(svg))
  end

  def test_renders_large_count
    svg = render(alive: 1234, dead: 5678)
    refute_includes(svg, '99+', "badge must show real numbers, got: #{svg}")
    assert_equal('1234/6912', count_text(svg))
  end

  def test_widens_to_fit_large_numbers
    [0, 5, 99, 100, 1000, 100_000].each do |alive|
      svg = render(alive: alive)
      width = badge_width(svg)
      text = count_text(svg)
      # 47 px label area + per-character advance ~6.5 + 7 px right padding
      min = 47 + (text.length * 6.5) + 7
      assert_operator(width, :>=, min,
                      "badge width #{width} too narrow for #{text.inspect} (alive=#{alive})")
    end
  end

  def test_text_anchor_stays_inside_badge
    [0, 5, 99, 100, 1000, 100_000].each do |alive|
      svg = render(alive: alive)
      doc = Nokogiri::XML(svg)
      width = doc.root['width'].to_f
      doc.xpath('//*[local-name()="text" and @text-anchor="end"]').each do |t|
        x = t['x'].to_f
        assert_operator(x, :<=, width, "anchor x=#{x} outside width=#{width} for alive=#{alive}")
        assert_operator(x, :>=, 47, "anchor x=#{x} crosses into label area for alive=#{alive}")
      end
    end
  end
end
