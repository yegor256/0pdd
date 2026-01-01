<?xml version="1.0" encoding="UTF-8"?>
<!--
 * SPDX-FileCopyrightText: Copyright (c) 2016-2026 Yegor Bugayenko
 * SPDX-License-Identifier: MIT
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="1.0" exclude-result-prefixes="xs">
  <xsl:output method="xml"/>
  <xsl:strip-space elements="*"/>
  <xsl:key name="existing" match="//puzzle" use="id"/>
  <xsl:key name="extras" match="//extra" use="id"/>
  <xsl:template match="/puzzles">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates select="//puzzle[id!='unknown']"/>
      <xsl:apply-templates select="//extra[not(key('existing',id))]"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="puzzle|extra">
    <puzzle>
      <xsl:attribute name="alive">
        <xsl:choose>
          <xsl:when test="key('extras',id)">
            <xsl:text>true</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>false</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:choose>
        <xsl:when test="issue">
          <xsl:apply-templates select="issue"/>
        </xsl:when>
        <xsl:otherwise>
          <issue>
            <xsl:text>unknown</xsl:text>
          </issue>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="ticket|estimate|role|id|lines|body|file|author|email|time"/>
    </puzzle>
  </xsl:template>
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
