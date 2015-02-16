<!--

 4.xsl

    Copyright ©, 2004-2006, International Business Machines

    This file is part of SrcRpt.
  
    SrcRpt is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, version 2.0.

    SrcRpt is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with SrcRpt.  If not, see http://www.gnu.org/licenses/.

-->

<!-- author Bill Spurlin wj@spurlin.org -->

<xsl:stylesheet version="1.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:msxsl="urn:schemas-microsoft-com:xslt"
	>
	<xsl:include href="srcrpti.xsl"/>
	<xsl:output method="xml" omit-xml-declaration="yes"/>
	<xsl:key name="uql" match="//uniqline" use="@id" />
	<xsl:param name="keyword" select="0" />
    <xsl:param name="nooldcolors" />
    <xsl:param name="doneoff" />
    <xsl:variable name="key" select="//keyword[@keyid=$keyword]" />
	<!-- template rules -->

	<xsl:template match="/">
		<xsl:apply-templates select="/srcrpt/summary" />
	</xsl:template>

	<!-- Template rule for keyword element(s): -->
	<xsl:template match="summary">
	<!-- Output a table with heading cells. -->

	<xsl:variable name="term" >
		<xsl:choose>
			<xsl:when test="/srcrpt/srchead/keywords/term[@keyid=$keyword]">
				<xsl:value-of select="/srcrpt/srchead/keywords/term[@keyid=$keyword]"/>
			</xsl:when>
			<xsl:otherwise><xsl:value-of select="//file/line[@keyid=$keyword]"/></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	
	<xsl:variable name="noteid" >
		<xsl:value-of select="/srcrpt/srchead/keywords/term[@keyid=$keyword]/@note"/>
		<xsl:value-of select="//file/line[@keyid=$keyword]/@note"/>
	</xsl:variable>

	<TABLE  border="1" id="keywordTable" noteid="{$noteid}" cellspacing="0">
		<TR nkid="{$keyword}">
		  <TH oncontextmenu="parent.nukem('keywordTable','keywordTable')">
		  <xsl:value-of select="$term"/>
			<xsl:if test="$noteid > 0">
			<TABLE>		  
				<TR>
					<TD colspan="3" style="background-color:yellow">
					<xsl:value-of select="/srcrpt/annotations/note[@noteid=$noteid]"/>
					</TD>
				</TR>
			</TABLE>
			</xsl:if>
		  </TH>
		  <TH>Qty</TH>
		  <TH>Go</TH>
		</TR>
		<xsl:call-template name="KeywordHitRows">
			<xsl:with-param name="keyword" select="$keyword" />
			<xsl:with-param name="nooldcolors" select="$nooldcolors" />
			<xsl:with-param name="doneoff" select="$doneoff" />
		</xsl:call-template>
	</TABLE>
	
	<xsl:call-template name="KeywordMenuDiv"/>
	<xsl:call-template name="ULMenuDiv"/>
	</xsl:template>
</xsl:stylesheet>
