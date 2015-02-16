<?xml version="1.0"?>

<!--

 5.xsl

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


<!-- point and click into the file from a table of filenames matching the unique line -->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:param name="hitid" select="0"/>
  <xsl:param name="keyword" select="0"/>
	<xsl:output method="xml" omit-xml-declaration="yes"/>
  
  <xsl:template match="/">
    <xsl:apply-templates select="/srcrpt/hits"/> 
  </xsl:template>
  
  
  <xsl:template match="hits">
    <xsl:variable name="uniqueline" select="/srcrpt/uniqlines/uniqline[@id=$hitid]"/>
	<xsl:variable name="analyzed" select="$uniqueline/@analysis"/>
	<xsl:variable name="analysiscolor">
			<xsl:choose>
				<xsl:when test="$analyzed='I'">#FF4040</xsl:when>
				<xsl:when test="$analyzed='nI'">#40FF40</xsl:when>
				<xsl:otherwise></xsl:otherwise>
			</xsl:choose>
	</xsl:variable> 
    
     <xsl:variable name="kw" select="//term[@keyid=$keyword]" />
     <xsl:variable name="key" select="/srcrpt/summary/keyword[@keyid=$keyword]" />
 		<table ulid='{$hitid}' id="UL_{$hitid}" oncontextmenu="parent.nukem('UL_{$hitid}','nukeUL')" border="1">
    		<tr ><td><i>Keyphrase:</i></td><td><b><xsl:value-of select="$kw"/></b></td></tr>
			<tr >
				<td style="background-color:{$analysiscolor}"><i>Uniqline:</i>
				</td>
				<td><xsl:value-of select="$uniqueline"/>
					<xsl:if test="$uniqueline/@note">
					<table>
					<TR>
						<TD  align="right" style="background-color:yellow">
						<xsl:value-of select="/srcrpt/annotations/note[@noteid=$uniqueline/@note]"/>
						</TD>
					</TR>
					</table>
					</xsl:if>
				</td>
			</tr>
 		</table>

    <pre id="UNIQLINE"><xsl:value-of select="$uniqueline"/></pre>
    <p></p>
    <TABLE border="1">
      <TR>
         <TH align="left">Match</TH>
         <TH align="left">File</TH>
      </TR>      
      <xsl:for-each select = "./file/line[@ulid=$hitid and @keyid=$keyword]">
        <xsl:variable name="number"><xsl:number level="any"/></xsl:variable>
	<xsl:variable name="match_l" select="@match" />
        <tr oncontextmenu="parent.nukem('{../@name}','nukeFIL')">
        	<td><xsl:value-of select="$match_l" /></td>
          <td style="background-color:{../@color}">
            <a href="javascript:parent.iwindowset('{$keyword}','file_{$number}','{$match_l}')" id="file_{$number}">
              <xsl:value-of select = "../@name"/>
            </a>
          </td>
        </tr>  
      </xsl:for-each><p></p>
    </TABLE>

<DIV id="nukeULMenuDiv" style="DISPLAY: none">
  <TABLE style="BORDER: none; FONT: smaller sans-serif;Z-INDEX: 3; BACKGROUND: #d0d0c8; LEFT: 0px; POSITION: absolute; TOP: 0px; HEIGHT: 100px">
	<TR><TD id="nukeKey" style="BORDER: black 1px solid; CURSOR: hand; COLOR: #0" >
		<INPUT type="radio" name="keyrad" checked="true" onclick="javascript:parent.singleUL(0,'nukeUL')">Default</INPUT>
		<INPUT type="radio" name="keyrad" onclick="javascript:parent.singleUL(1,'nukeUL')">Active</INPUT>
		<INPUT type="radio" name="keyrad" onclick="javascript:parent.singleUL(2,'nukeUL')">Done</INPUT>
	</TD></TR>
	<TR><TD align="center" style="BORDER: black 1px solid; CURSOR: hand; COLOR: #0" >
		<BUTTON name="annotate"  onclick="javascript:parent.annotate_menu('nukeUL')">Annotate</BUTTON>		
	</TD></TR>
  </TABLE>
</DIV>

  </xsl:template>
      
  </xsl:stylesheet>
  
