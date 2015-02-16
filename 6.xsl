<?xml version="1.0" ?>
<!--

 6.xsl

    Copyright ©, 2004,2005, International Business Machines

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


<!-- file-by-file report meant for diff scans only -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
        <xsl:include href="srcrpti.xsl"/>
	<xsl:output method="html" />
	<xsl:key name="uql" match="//uniqline" use="@id" />
	<xsl:param name="nooldcolors" />
	<xsl:param name="doneoff" />

	<!-- template rules -->

	<xsl:template match="/">
		<xsl:apply-templates select="/srcrpt/hits"/>
	</xsl:template>

	<xsl:template match="hits">
		<TABLE border="1">
			<xsl:for-each select="./file">
				<xsl:variable name="fn" select="@name" />
				<tr>
					<td style="background-color:{@color}">
						<h4>
							<a href='{$fn}' target="mywindow" oncontextmenu="parent.nukem('{$fn}','nukeFIL')">
								<xsl:value-of select="$fn" />
							</a>
						</h4>
					</td>
					<td width="3">F</td>
				</tr>
				<xsl:for-each select="./line">
				<xsl:variable name="ulid" select="@ulid" />
				<xsl:variable name="ul" select="key('uql',$ulid)" />
				<xsl:variable name="color" select="$ul/@color" />
				<xsl:variable name="analyzed" select="$ul/@analysis"/>
				<xsl:variable name="done" select="$analyzed='nI'" />
				<xsl:variable name="analysiscolor">
					<xsl:choose>
						<xsl:when test="$analyzed='I'">#FF4040</xsl:when>
						<xsl:when test="$analyzed='nI'">#40FF40</xsl:when>
						<xsl:otherwise></xsl:otherwise>
					</xsl:choose>
				</xsl:variable> 
				<xsl:variable name="analysisfont">
					<xsl:choose>
						<xsl:when test="$analyzed='I'">larger sans-serif</xsl:when>
						<xsl:when test="$analyzed='nI'">xx-small sans-serif</xsl:when>
						<xsl:otherwise></xsl:otherwise>
					</xsl:choose>
				</xsl:variable> 
				<xsl:if test="($color!='#80FFFF' or $nooldcolors!=1) and (($done and $doneoff)=false())">
					<TR style="FONT: {$analysisfont}"  id="{$ulid}" nkid = "{$ulid}">
					<xsl:call-template name="KeywordHitSingleCell">
						<xsl:with-param name="ul" select="$ul" />
						<xsl:with-param name="ulid" select="$ulid" />
						<xsl:with-param name="color" select="$color" />
					</xsl:call-template>					
					<TD align="right" style="background-color:{$analysiscolor}" width="3">						
					</TD>
					</TR>
				</xsl:if>
                                </xsl:for-each>
			</xsl:for-each>
			<p></p>
		</TABLE>

        <xsl:call-template name="KeywordMenuDiv"/>
        <xsl:call-template name="ULMenuDiv"/>

	</xsl:template>
</xsl:stylesheet>
