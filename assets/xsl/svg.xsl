<?xml version="1.0" encoding="UTF-8"?>
<!--
 * SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
 * SPDX-License-Identifier: MIT
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/2000/svg" version="1.0">
  <xsl:output method="xml" omit-xml-declaration="yes"/>
  <xsl:template match="/puzzles">
    <xsl:variable name="alive" select="count(//puzzle[@alive='true'])"/>
    <xsl:variable name="total" select="count(//puzzle)"/>
    <xsl:variable name="count" select="concat($alive, '/', $total)"/>
    <xsl:variable name="advance" select="47 + (string-length($count) * 6.5) + 7"/>
    <xsl:variable name="width">
      <xsl:choose>
        <xsl:when test="$advance &gt; 86">
          <xsl:value-of select="ceiling($advance)"/>
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
        <path fill="#4c1" d="M47 0h{$width - 47}v20H47z"/>
        <path fill="url(#b)" d="M0 0h{$width}v20H0z"/>
      </g>
      <g fill="#fff" text-anchor="middle" font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="11">
        <text x="19.5" y="15" fill="#010101" fill-opacity=".3">0pdd</text>
        <text x="19.5" y="14">0pdd</text>
        <text x="{$width - 3.5}" y="15" fill="#010101" fill-opacity=".3" text-anchor="end">
          <xsl:value-of select="$count"/>
        </text>
        <text x="{$width - 3.5}" y="14" text-anchor="end">
          <xsl:value-of select="$count"/>
        </text>
      </g>
    </svg>
  </xsl:template>
</xsl:stylesheet>
