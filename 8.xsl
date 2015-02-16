<!--

 8.xsl

    Copyright ©, 2006,2007 International Business Machines

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
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="html" />
<xsl:param name="hitid" select="0" />

<!-- template rules -->

<xsl:template match="/">
	<xsl:apply-templates select="/srcrpt/summary" />
</xsl:template>


<xsl:template match="summary">
<form  name="noteForm" onSubmit="parent.processNote('{$hitid}')">
  <table style="WIDTH: 100%; BORDER: none; FONT: smaller sans-serif;Z-INDEX: 3; BACKGROUND: #d0d0c8; LEFT: 0px; POSITION: absolute; TOP: 0px; HEIGHT: 100%">
  <tr height="10%"><th style="BORDER: black 1px solid; CURSOR: hand; COLOR: #0">Add, Edit or Delete a Note</th></tr>
  <tr><td style="BORDER: black 1px solid; CURSOR: hand; COLOR: #0" >
  	<select style="width: 680px" name="noteSelect">
  		<option>None</option>
		<xsl:for-each select="/srcrpt/annotations/note">
			<option id="{./@noteid}"><xsl:value-of select="."/></option>
		</xsl:for-each>
	</select>
	</td></tr>
	<tr><td>
	<input size="100" id="noteTextId" name="noteText" hitid="{$hitid}" value="None" type="text"></input>
	<button id="delButton" style="display:none" onclick="parent.deleteNote('{$hitid}')" >Del</button>
	</td>	
	</tr>
  <tr height="10%"><td><input class="x2controls" type="submit" value="Submit Note"></input></td></tr>
  </table>		
</form>
</xsl:template>

</xsl:stylesheet>
