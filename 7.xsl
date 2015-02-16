<!--

 7.xsl

    Copyright ©, 2006 - 2009, International Business Machines

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
 of unique lines matched. Additionally calculate how many UL's have
 been analyzed and annotated and place info in columns.
-->

<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:key name="uql" match="//uniqline" use="@id" />
<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8"/>

<!-- template rules -->

<xsl:template match="/">
	<xsl:apply-templates select="/srcrpt/summary" />
</xsl:template>

<!-- 
	IdsByIds 
	INPUT: param nodeList with numeric id
	REFERENCES: uniqline with id and analysis attributes
	DERIVES: The number 1 for any active or done uniqline
	TOTALS: The number of active ("I") and done ("nI") uniqlines
	RETURNS: <done>,<active>,<number of notes> totals
	DVC algorithm inspired by, but no code copied from, "Two-stage recursive algorithms in XSLT"
	Dimitre Novatchev and Slawomir Tyszko, http://topxml.com/xsl/articles/recurse/
-->

<xsl:template name="IdsByIds">
	<xsl:param name="nodeList" select = "/.."/>
	<xsl:param name="result"  select="0"/>
	<xsl:param name="keyword_id" />
	<xsl:variable name="nNodes" 
		select="count($nodeList)" />
	<xsl:choose>
		<xsl:when test="$nNodes &lt; 1">0</xsl:when>
		<xsl:when test="$nNodes=1">
			<xsl:variable name="firstid" select = "$nodeList[1]/@ulid" />
			<xsl:variable name="ul" select="key('uql',$firstid)" />		
			<xsl:variable name="analysis" select="$ul/@analysis"/>
			<xsl:variable name="ni">
			<xsl:choose>
				<xsl:when test="$analysis = 'nI'"><xsl:value-of select="1"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="0"/></xsl:otherwise>
			</xsl:choose>
			</xsl:variable>		
			<xsl:variable name="i">
			<xsl:choose>
				<xsl:when test="$analysis = 'I'"><xsl:value-of select="1"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="0"/></xsl:otherwise>
			</xsl:choose>
			</xsl:variable>
			<xsl:variable name="nnotes">
			<xsl:choose>
				<xsl:when test="$ul/@note"><xsl:value-of select="1"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="0"/></xsl:otherwise>
			</xsl:choose>
			</xsl:variable>
<!-- IdsByIds returns an "array" of <done>,<active>,<nnotes> totals. The addition is done here -->
			<xsl:value-of select="substring-before($result,',') + $ni" />	
			<xsl:value-of select="','"/>	
			<xsl:value-of select="substring-before(substring-after($result,','),',') + $i" />
			<xsl:value-of select="','"/>
			<xsl:value-of select="substring-after(substring-after($result,','),',') + $nnotes" />
		</xsl:when>
		<xsl:otherwise>
			<xsl:variable name="nHalf" 
				select="floor($nNodes div 2)" />

			<xsl:variable name="lowerhalf">
				<xsl:call-template name="IdsByIds">
					<xsl:with-param name="keyword_id" select="$keyword_id"/>
					<xsl:with-param name="nodeList" 
						select="$nodeList[position() &lt;= $nHalf]" />
					<xsl:with-param name="result"
						select="$result" />
				</xsl:call-template>
			</xsl:variable>

			<xsl:call-template name="IdsByIds">
				<xsl:with-param name="keyword_id" select="$keyword_id"/>
				<xsl:with-param name="nodeList" 
					select="$nodeList[position() > $nHalf]" />
				<xsl:with-param name="result"
					select="$lowerhalf" />
			</xsl:call-template>

		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

  
<!-- Template rule for analyzed keywords -->
<xsl:template match="summary">
	<!-- Instantiate a table with heading cells. -->
	<TABLE width="800" border="1" cellspacing="0">
	<tr><th width="700">Keyword</th><th width="10">Uniqls</th><th width="10">Active</th><th width="10" style="FONT:smaller">Analyzed</th><th width="10">%</th></tr>
	<!-- For each <keyword> element,
		instantiate a table row and three cells. Data in the cells
		will be the keyword, number of unique lines, number of active UL's and percentage of UL's analyzed.
	-->
	<xsl:for-each select="./keyword">
	<xsl:variable name="keyword_id"  select="./@keyid"/>

	<xsl:variable name="noteid" >
		<xsl:value-of select="/srcrpt/srchead/keywords/term[@keyid=$keyword_id]/@note"/>
		<xsl:value-of select="//file/line[@keyid=$keyword_id]/@note"/>
	</xsl:variable>

	<TR>
		<xsl:variable name="numhits" select="count(./hit)"/>

		<xsl:variable name="s" >
			<xsl:choose>
			<xsl:when test="$numhits">
			<xsl:call-template name="IdsByIds">
				<xsl:with-param name="keyword_id" select="$keyword_id"/>
				<xsl:with-param name="nodeList" select="./hit"/>
				<xsl:with-param name="result" select="'0,0,0'"/>
			</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>0,0,0</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
<!-- n is the number of done or "non-interesting" UL's -->
		<xsl:variable name="n" select="substring-before($s,',')"/>
<!-- i is the number of active or "interesting" UL's -->
		<xsl:variable name="i" select="substring-before(substring-after($s,','),',')"/>
		
		<xsl:variable name="nnotes" select="substring-after(substring-after($s,','),',')"/>

		<xsl:variable name="done" select="($i + $n) div $numhits"/>

		<xsl:variable name="activecolor">
			<xsl:choose>
<!-- Turn activecolor a light yellow when analyzed is 100% and there are both interesting and non-interesting -->
				<xsl:when test="$i != 0 and $i != $numhits and $done = 1">
					<xsl:value-of select="'#FFFFD0'" />
				</xsl:when>				
				<xsl:when test="$i != 0 and $done = 1 ">
					<xsl:value-of select="'#FFD0D0'" />
				</xsl:when>
				<xsl:when test="$done = 1">
					<xsl:value-of select="'#D0FFD0'" />
				</xsl:when>
				<xsl:otherwise/>
			</xsl:choose>
		</xsl:variable>

		<TD align="left"><a href="javascript:parent.keywordhits('{$keyword_id}')">
		<xsl:choose>
			<xsl:when test="//term[@keyid=$keyword_id]"><xsl:value-of select="//term[@keyid=$keyword_id]"/></xsl:when>
			<xsl:otherwise><xsl:value-of select="//file/line[@keyid=$keyword_id]"/></xsl:otherwise>
		</xsl:choose>
		</a>
		<xsl:if test="$noteid > 0">
		 &#160;&#160;
<!-- Put the overall note for the term, if any, here -->
                  <span  style="background-color:yellow" ><xsl:value-of select="/srcrpt/annotations/note[@noteid=$noteid]"/></span>
		</xsl:if>
<!-- Create a table for a keyword or term, under the following conditions -->

		<xsl:if test="$nnotes > 0 or  $i > 0 or $noteid > 0">
		<TABLE border="1">
		<xsl:for-each select="./hit">
		    <xsl:variable name="ul" select="key('uql',@ulid)"/>
		    <xsl:if test="$ul/@analysis='I' or $ul/@note">
			<xsl:variable name="hitcolor">
				<xsl:choose>
				<xsl:when test="$ul/@analysis='I'">
					<xsl:value-of select="'#FFD0D0'" />
				</xsl:when>
				<xsl:when test="$ul/@analysis='nI'">
					<xsl:value-of select="'#D0FFD0'" />
				</xsl:when>
				<xsl:otherwise/>
				</xsl:choose>
			</xsl:variable>
			<TR><TD  style="background-color:{$hitcolor}" ><xsl:value-of select="$ul"/>
			<xsl:if test="$ul/@note"><p></p>
			<FONT style="background-color:#FFFF00">
				<xsl:value-of select="/srcrpt/annotations/note[@noteid=$ul/@note]"/>
			</FONT>
			</xsl:if>
			</TD></TR>
		    </xsl:if>
		</xsl:for-each> 
		</TABLE>
		</xsl:if>

		</TD>
		<td><xsl:value-of select="$numhits"/></td>
		<td  style="background-color:{$activecolor}"><xsl:value-of select="$i"/></td>
		<td><xsl:value-of select="$i + $n"/></td>
		<td  align="right">
			<xsl:choose>
				<xsl:when test="$numhits">
					<xsl:value-of  select="format-number($done,'#.00%')"/>
				</xsl:when>
				<xsl:otherwise></xsl:otherwise>
			</xsl:choose>
		</td>
	</TR>
	</xsl:for-each>
	</TABLE>
</xsl:template>


</xsl:stylesheet>
