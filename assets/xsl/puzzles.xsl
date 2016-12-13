<?xml version="1.0"?>
<!--
 * Copyright (c) 2016 Yegor Bugayenko
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the 'Software'), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml" version="1.0">
    <xsl:output method="xml" omit-xml-declaration="yes"/>
    <xsl:template match="/puzzles">
        <html>
            <head>
                <meta charset="UTF-8"/>
                <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
                <meta name="description" content="puzzles"/>
                <meta name="keywords" content="puzzles"/>
                <meta name="author" content="0pdd.com"/>
                <title>puzzles</title>
                <link type="text/css" href="/css/main.css" rel="stylesheet"/>
                <link rel="shortcut icon" href="https://avatars2.githubusercontent.com/u/24456188"/>
            </head>
            <body>
                <div style="padding: 15px;">
                    <p>
                        <img class="logo" src="https://avatars2.githubusercontent.com/u/24456188"/>
                    </p>
                    <p>
                        <xsl:text>Updated by </xsl:text>
                        <a href="http://www.0pdd.com">
                            <xsl:text>0pdd v</xsl:text>
                            <xsl:value-of select="@version"/>
                        </a>
                        <xsl:text> on </xsl:text>
                        <xsl:value-of select="@date"/>
                        <xsl:text>.</xsl:text>
                    </p>
                    <p>
                        <xsl:value-of select="count(//puzzle)"/>
                        <xsl:text> total, </xsl:text>
                        <xsl:value-of select="count(//puzzle[@alive='true'])"/>
                        <xsl:text> alive.</xsl:text>
                    </p>
                    <xsl:apply-templates select="puzzle"/>
                </div>
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
                <xsl:apply-templates select="id"/>
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
    <xsl:template match="id">
        <xsl:choose>
            <xsl:when test="../@alive='true'">
                <strong><xsl:apply-templates select="." name="linked"/></strong>
            </xsl:when>
            <xsl:otherwise>
                <strike><xsl:apply-templates select="." name="linked"/></strike>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="id" name="linked">
        <xsl:choose>
            <xsl:when test="@href">
                <a href="{@href}"><xsl:value-of select="."/></a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
