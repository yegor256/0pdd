<?xml version="1.0"?>
<!--
(The MIT License)

Copyright (c) 2016-2017 Yegor Bugayenko

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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml" version="1.0">
  <xsl:output method="xml" omit-xml-declaration="yes"/>
  <xsl:param name="version"/>
  <xsl:param name="project"/>
  <xsl:param name="length"/>
  <xsl:template match="/puzzles">
    <html>
      <head>
        <meta charset="UTF-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <meta name="description" content="{$project}"/>
        <meta name="keywords" content="{$project}"/>
        <meta name="author" content="0pdd.com"/>
        <title>
          <xsl:value-of select="$project"/>
        </title>
        <link type="text/css" href="/css/main.css" rel="stylesheet"/>
        <link rel="shortcut icon" href="https://avatars2.githubusercontent.com/u/24456188"/>
      </head>
      <body>
        <p>
          <a href="http://www.0pdd.com">
            <img class="logo" src="https://avatars2.githubusercontent.com/u/24456188"/>
          </a>
        </p>
        <p>
          <img src="/svg?name={$project}"/>
        </p>
        <p>
          <xsl:value-of select="count(//puzzle[@alive='true'])"/>
          <xsl:text> alive, </xsl:text>
          <xsl:value-of select="count(//puzzle)"/>
          <xsl:text> total.</xsl:text>
        </p>
        <xsl:apply-templates select="puzzle"/>
        <p>
          <xsl:text>--</xsl:text>
        </p>
        <p>
          <xsl:text>Full </xsl:text>
          <a href="/log?name={$project}">
            <xsl:text>log</xsl:text>
          </a>
          <xsl:text> of recent events.</xsl:text>
        </p>
        <p>
          <xsl:text>Download </xsl:text>
          <a href="/xml?name={$project}">
            <xsl:text>XML</xsl:text>
          </a>
          <xsl:text> (</xsl:text>
          <span title="{$length} bytes">
            <xsl:value-of select="format-number($length div 1024, '#.0')"/>
            <xsl:text> Kb</xsl:text>
          </span>
          <xsl:text>).</xsl:text>
        </p>
        <p>
          <xsl:text>Project "</xsl:text>
          <xsl:value-of select="$project"/>
          <xsl:text>" updated by </xsl:text>
          <a href="http://www.0pdd.com">
            <xsl:text>0pdd</xsl:text>
          </a>
          <xsl:text> v</xsl:text>
          <xsl:value-of select="@version"/>
          <xsl:text> on </xsl:text>
          <xsl:value-of select="@date"/>
          <xsl:text>.</xsl:text>
        </p>
        <p>
          <a href="http://www.0pdd.com" title="Current version of 0pdd is {$version}">
            <xsl:value-of select="$version"/>
          </a>
        </p>
      </body>
    </html>
  </xsl:template>
  <xsl:template match="puzzle">
    <div>
      <span>
        <xsl:if test="@alive = 'false'">
          <xsl:attribute name="style">
            <xsl:text>color:gray;</xsl:text>
          </xsl:attribute>
        </xsl:if>
        <xsl:apply-templates select="id" mode="fonted"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="file"/>
        <xsl:text>:</xsl:text>
        <xsl:value-of select="lines"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="estimate"/>
        <xsl:text>min </xsl:text>
      </span>
      <xsl:if test="children/puzzle">
        <div style="margin-left: 2em;">
          <xsl:apply-templates select="children/puzzle"/>
        </div>
      </xsl:if>
    </div>
  </xsl:template>
  <xsl:template match="id" mode="fonted">
    <xsl:choose>
      <xsl:when test="../@alive='true'">
        <xsl:apply-templates select="." mode="linked"/>
      </xsl:when>
      <xsl:otherwise>
        <strike>
          <xsl:apply-templates select="." mode="linked"/>
        </strike>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="id" mode="linked">
    <xsl:choose>
      <xsl:when test="../issue/@href">
        <a href="{../issue/@href}" style="color:inherit">
          <xsl:value-of select="."/>
        </a>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
