<!--
 srcrpti.xsl

    Copyright ©, 2006, International Business Machines

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


<!-- author wspurlin@us.ibm.com -->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">


<xsl:template name="KeywordMenuDiv">
<DIV id="nukeKeyMenuDiv" style="DISPLAY: none">

  <TABLE style="BORDER: none; font-family: sans-serif;font-size: 14px;Z-INDEX: 3; BACKGROUND: #d0d0c8; LEFT: 0px; POSITION: absolute; TOP: 0px; HEIGHT: 100px">
	<TR><TD style="BORDER: black 1px solid; CURSOR: hand; COLOR: #0" >
		<INPUT type="radio" name="keyrad" onclick="javascript:parent.ulTable(0,'keywordTable')">Default</INPUT>
		<INPUT type="radio" name="keyrad" onclick="javascript:parent.ulTable(1,'keywordTable')">Active-all</INPUT>
		<INPUT type="radio" name="keyrad" onclick="javascript:parent.ulTable(2,'keywordTable')">Done-all</INPUT>
	</TD></TR>
	<TR><TD style="BORDER: black 1px solid; CURSOR: hand; COLOR: #0" >		
		<INPUT type="radio" name="keyrad" onclick="javascript:parent.ulTable(3,'keywordTable')">Active-insert</INPUT>
		<INPUT type="radio" name="keyrad" onclick="javascript:parent.ulTable(4,'keywordTable')">Done-insert</INPUT>
	</TD></TR>
	<TR><TD align="center" style="BORDER: black 1px solid; CURSOR: hand; COLOR: #0" >
		<BUTTON name="annotate"  onclick="javascript:parent.annotate_menu('keywordTable')">Annotate</BUTTON>		
	</TD></TR>
  </TABLE>


</DIV>
</xsl:template>

<xsl:template name="ULMenuDiv">
<DIV id="nukeULMenuDiv" style="DISPLAY: none">

  <TABLE style="BORDER: none; font-family: sans-serif;font-size: 14px;Z-INDEX: 3; BACKGROUND: #d0d0c8; LEFT: 0px; POSITION: absolute; TOP: 0px; HEIGHT: 100px">
	<TR><TD id="nukeKey" style="BORDER: black 1px solid; CURSOR: hand; COLOR: #0" >
		<INPUT type="radio" name="keyrad" checked="true" onclick="javascript:parent.ulTable(0,'nukeUL')">Default</INPUT>
		<INPUT type="radio" name="keyrad" onclick="javascript:parent.ulTable(1,'nukeUL')">Active</INPUT>
		<INPUT type="radio" name="keyrad" onclick="javascript:parent.ulTable(2,'nukeUL')">Done</INPUT>
	</TD></TR>
	<TR><TD align="center" style="BORDER: black 1px solid; CURSOR: hand; COLOR: #0" >
		<BUTTON name="annotate"  onclick="javascript:parent.annotate_menu('nukeUL')">Annotate</BUTTON>		
	</TD></TR>
	<TR><TD align="center" style="BORDER: black 1px solid; CURSOR: hand; COLOR: #0" >
		<BUTTON name="setsubstringdone"  onclick="javascript:parent.setsubstringdone_menu('nukeUL')">Set Substring Done</BUTTON>		
	</TD></TR>
  </TABLE>

</DIV>
</xsl:template>
<!--
	KeywordHitRows
	Called from 2.xsl and 4.xsl.
	Depends on a key named "uql" instantiated in each of those.
-->
<xsl:template name="KeywordHitRows">
	<xsl:param name="keyword" select="0" />
	<xsl:param name="nooldcolors" />
	<xsl:param name="doneoff" />
	<xsl:variable name="colornodes" select="/srcrpt/summary/keyword[@keyid=$keyword]" ></xsl:variable>
	<xsl:variable name="keyid" select="$colornodes/@keyid"/>
<!-- 
	For each <hit> uniqline (UL) child of the <keyword> element,
	output a table row and three cells. Data in the cells
	will be the uniqline pcdata, the value of the <hit> element's hitcount
	attribute and a link to a file-by-file page showing each file having
	hits on that UL. 
	
	Set colors for a diff scan and Done or Active attributes, 
	and turn off display for old-distribution and Done uL's as required.
-->
		<xsl:for-each select="$colornodes">
			<xsl:for-each select="./hit">
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
						<TD align="right" style="background-color:{$analysiscolor}">
							<xsl:value-of select="@hitcount" />
						</TD>
						<TD align="right" style="background-color:{$analysiscolor}">
							<a href="javascript:parent.filehits({$ulid},'{$keyword}','{$keyid}')"> hits </a>
						</TD>
<!--					<TD><xsl:value-of select="$done=false()" />__<xsl:value-of select="($done and $doneoff)=false()" /></TD>-->
				</TR>
				</xsl:if>
			</xsl:for-each>
		</xsl:for-each>
</xsl:template>

<xsl:template name="KeywordHitSingleCell">
	<xsl:param name="ul" />
	<xsl:param name="ulid" />
	<xsl:param name="color" />
	<td	style="background-color:{$color}" ulid="{$ulid}" id="UL_{$ulid}" 
		oncontextmenu="parent.nukem('UL_{$ulid}','nukeUL')">

	<!-- Highlight the keyword in the hit using the match attribute.
             The value of the match attribute preserves case. -->

		<xsl:value-of select="substring-before($ul,@match)" />
		<font color="red">
			<xsl:value-of select="@match" />
		</font>
		<xsl:value-of select="substring-after($ul,@match)" />
		<xsl:if test="$ul/@note">
			<table>
				<TR>
					<TD  align="right" style="background-color:yellow">
						<xsl:value-of select="/srcrpt/annotations/note[@noteid=$ul/@note]"/>
					</TD>
				</TR>
			</table>
		</xsl:if>
	</td>
</xsl:template>

</xsl:stylesheet>
