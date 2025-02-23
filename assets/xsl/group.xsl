<?xml version="1.0" encoding="UTF-8"?>
<!--
 * SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
 * SPDX-License-Identifier: MIT
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="1.0" exclude-result-prefixes="xs">
  <xsl:output method="xml"/>
  <xsl:strip-space elements="*"/>
  <xsl:key name="issues" match="//puzzle" use="issue"/>
  <xsl:key name="roots" match="//puzzle[not(key('issues',ticket))]" use="id"/>
  <xsl:template match="/puzzles">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates select="//puzzle[key('roots',id)]"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="puzzle">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
      <children>
        <xsl:apply-templates select="//puzzle[ticket=current()/issue]"/>
      </children>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
