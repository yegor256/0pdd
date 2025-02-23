<?xml version="1.0" encoding="UTF-8"?>
<!--
 * SPDX-FileCopyrightText: Copyright (c) 2016-2025 Yegor Bugayenko
 * SPDX-License-Identifier: MIT
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="1.0" exclude-result-prefixes="xs">
  <xsl:output method="xml"/>
  <xsl:strip-space elements="*"/>
  <xsl:key name="extras" match="//extra" use="id"/>
  <xsl:template match="/puzzles">
    <xsl:copy>
      <xsl:apply-templates select="//puzzle[@alive='true' and not(key('extras',id)) and issue!='unknown']"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
