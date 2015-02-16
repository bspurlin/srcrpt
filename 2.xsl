<!--

 2.xsl

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


<!-- Create a long (and slow) report of each keyword and the distinct hits of that keyword -->

<xsl:stylesheet version="1.0"
     xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:include href="srcrpti.xsl"/>
   	<xsl:output method="xml" omit-xml-declaration="yes"/>
    <xsl:key name="uql" match="//uniqline" use="@id" />
    <xsl:param name="nooldcolors" select="1" />
    <xsl:param name="doneoff" />    


   <!-- template rules -->

   <xsl:template match="/">
         <xsl:apply-templates select="/srcrpt/summary" />
   </xsl:template>

   <!-- Template rule for keyword element(s): -->

   <xsl:template match="summary">
         <!-- For each <keyword> element,
              create a table of all <hit>s in that keyword -->
         <xsl:for-each select="./keyword">
			<xsl:variable name="keyword_id"  select="./@keyid"/>
			<xsl:variable name="keyword_by_name">
				<xsl:choose>
				<xsl:when test="//term[@keyid=$keyword_id]">
					<xsl:value-of select="//term[@keyid=$keyword_id]"/>
				</xsl:when>
				<xsl:otherwise><xsl:value-of select="//file/line[@keyid=$keyword_id]"/></xsl:otherwise>
			</xsl:choose>
			</xsl:variable>
             <h6>Keyword:</h6><i> <xsl:value-of select="$keyword_by_name"/></i>
             <h6> Unique Lines Matched:</h6><i> <xsl:value-of select="count(./hit)"/></i>

	<TABLE border="1" id="TAB_{$keyword_id}" cellspacing="0">
		<TR nkid="{$keyword_id}">
			<TH oncontextmenu="parent.nukem('TAB_{$keyword_id}','keywordTable')"><xsl:value-of select="$keyword_by_name"/>
 		  <TABLE>
 		  	<TR>
				<TD colspan="3" style="background-color:yellow">
				<xsl:value-of select="/srcrpt/annotations/note[@noteid=/srcrpt/srchead/keywords/term[@keyid=$keyword_id]/@note]"/>
				<xsl:value-of select="/srcrpt/annotations/note[@noteid=//file/line[@keyid=$keyword_id]/@note]"/>
				</TD>
			</TR>
		  </TABLE>
			</TH>
			<TH>Qty</TH>
			<TH>Go</TH>
 		</TR>
		<xsl:call-template name="KeywordHitRows">
			<xsl:with-param name="keyword" select="$keyword_id" />
			<xsl:with-param name="nooldcolors" select="$nooldcolors" />
			<xsl:with-param name="doneoff" select="$doneoff" />
		</xsl:call-template>
	</TABLE>
   </xsl:for-each>

	<xsl:call-template name="KeywordMenuDiv"/>
	<xsl:call-template name="ULMenuDiv"/>
   </xsl:template>


</xsl:stylesheet>
