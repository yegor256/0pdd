<?xml version="1.0"?>
<!--
(The MIT License)

Copyright (c) 2016-2025 Yegor Bugayenko

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the 'Software'), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/2000/svg" version="1.0">
  <xsl:output method="xml" omit-xml-declaration="yes"/>
  <xsl:template match="/puzzles">
    <xsl:variable name="total" select="count(//puzzle)"/>
    <xsl:variable name="width">
      <xsl:choose>
        <xsl:when test="$total &gt; 99">
          <xsl:text>106</xsl:text>
        </xsl:when>
        <xsl:when test="$total &gt; 50">
          <xsl:text>96</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>86</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <svg width="{$width}" height="20">
      <linearGradient id="b" x2="0" y2="100%">
        <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
        <stop offset="1" stop-opacity=".1"/>
      </linearGradient>
      <mask id="a">
        <rect width="{$width}" height="20" rx="3" fill="#fff"/>
      </mask>
      <g mask="url(#a)">
        <path fill="#555" d="M0 0h47v20H0z"/>
        <path fill="#4c1" d="M47 0h67v20H47z"/>
        <path fill="url(#b)" d="M0 0h{$width}v20H0z"/>
      </g>
      <g fill="#fff" text-anchor="middle" font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="11">
        <text x="19.5" y="15" fill="#010101" fill-opacity=".3">0pdd</text>
        <text x="19.5" y="14">0pdd</text>
        <text x="{$width - 3.5}" y="15" fill="#010101" fill-opacity=".3" text-anchor="end">
          <xsl:apply-templates select="." mode="count"/>
        </text>
        <text x="{$width - 3.5}" y="14" text-anchor="end">
          <xsl:apply-templates select="." mode="count"/>
        </text>
      </g>
    </svg>
  </xsl:template>
  <xsl:template match="puzzles" mode="count">
    <xsl:call-template name="number">
      <xsl:with-param name="value" select="count(//puzzle[@alive='true'])"/>
    </xsl:call-template>
    <xsl:text>/</xsl:text>
    <xsl:call-template name="number">
      <xsl:with-param name="value" select="count(//puzzle)"/>
    </xsl:call-template>
  </xsl:template>
  <xsl:template name="number">
    <xsl:param name="value"/>
    <xsl:choose>
      <xsl:when test="$value &gt; 99">
        <xsl:text>99+</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$value"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
