<!--

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


<!-- Create a table of keywords and the number of unique lines matched
 by each keyword, from which one can point and click into a table 
 of unique lines matched.
-->

<xsl:stylesheet version="1.0"
     xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="html" />
   <!-- template rules -->

   <xsl:template match="/">
	<xsl:apply-templates select="/srcrpt/summary" />
   </xsl:template>

   <!-- Template rule for keyword element(s): -->
   <xsl:template match="summary">
      <!-- Instantiate a table with heading cells. -->
      <TABLE border="1">
        <tr><th>Keyword</th><th>ULs</th><th>Hits</th></tr>
         <!-- For each <keyword> element,
              instantiate a table row and three cells. Data in the cells
              will be the keyword, number of unique lines and total hits.
              attribute. -->
         <xsl:for-each select="./keyword">
		<xsl:variable name="keyword_id"  select="./@keyid"/>
           <TR>
             <TD align="left" width="50%">
             	<a href="javascript:parent.keywordhits('{./@keyid}')">
				<xsl:choose>
				<xsl:when test="//term[@keyid=$keyword_id]">
					<xsl:value-of select="//term[@keyid=$keyword_id]"/>
				</xsl:when>
				<xsl:otherwise><xsl:value-of select="//file/line[@keyid=$keyword_id]"/></xsl:otherwise>
				</xsl:choose>
             	</a>
             </TD>
             <td width="25%"><xsl:value-of select="count(./hit)"/></td>
             <td width="25%"><xsl:value-of select="sum(./hit/@hitcount)"/></td>
           </TR>
         </xsl:for-each>
	<xsl:variable name="tot_uls" select="count(./keyword/hit)"/>
	<xsl:variable name="tot_hits" select="sum(./keyword/hit/@hitcount)" />
	<tr>
		<td>GOG = <xsl:value-of select="format-number($tot_hits div $tot_uls, '#####0.00')"/></td>
		<td><xsl:value-of select="$tot_uls"/></td><td><xsl:value-of select="$tot_hits"/></td>
	</tr>
      </TABLE>
   </xsl:template>

</xsl:stylesheet>
