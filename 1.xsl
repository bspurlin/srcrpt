<!--

 1.xsl

    Copyright ©, 2004, International Business Machines

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


<!-- Display the header information from the scan 
 describing when, where, and how the scan was created; how many files were in
 the distribution; which files were not scanned
-->


<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="html" />
<xsl:template match="/">
     <xsl:apply-templates select="/srcrpt/srchead|/srcrpt/licensefiles|/srcrpt/binaries"   /> 
</xsl:template>

<xsl:template match="srchead">
<xsl:apply-templates/> 
</xsl:template>

<xsl:template match="timestamp">
<div>
<ul>
<li>Timestamp: <xsl:value-of select="."/></li>
<li>Username: <xsl:value-of select="./@username"/></li>
<li>Hostname: <xsl:value-of select="./@hostname"/></li>
</ul>
</div>
</xsl:template>

<xsl:template match="commandline">
<div><h4>Commandline: </h4><xsl:value-of select="."/></div>
</xsl:template>
<xsl:template match="keywordfile">
<div><h4>Keywordfile: </h4><xsl:value-of select="."/></div>
</xsl:template>

<xsl:template match="keywords">
  <div><p>
      <TABLE border="1">
      <tr><th>Keywords</th></tr>
      <xsl:for-each select="./term">
          <tr><td><xsl:value-of select="."/></td></tr>
      </xsl:for-each>
      </TABLE>
  </p></div>
</xsl:template>

<xsl:template match="startdir">
  <div><p>
      <TABLE border="1">
      <tr><th>Directories Scanned: <I style="FONT: smaller sans-serif">
	<xsl:value-of select="."/></I></th></tr>
      <xsl:for-each select="./dir">
          <tr><td><xsl:value-of select="."/></td></tr>
      </xsl:for-each>
      </TABLE>
  </p></div>
</xsl:template>

<xsl:template match="excluded">
  <div><p>
      <TABLE border="1">
      <tr><th>Exclusions: <xsl:value-of select="./@n" /> files not scanned with prefixes or suffixes</th></tr>
      <xsl:for-each select="./prefixorsuffix">
          <tr><td><xsl:value-of select="."/></td></tr>
      </xsl:for-each>
      </TABLE>
  </p></div>
</xsl:template>

<xsl:template match="excludedfiles">
  <div><p>
      <TABLE border="1">
      <tr><th>Files excluded by prefix or suffix</th></tr>
      <xsl:for-each select="./excludedfile">
          <tr><td><xsl:value-of select="./@name"/></td></tr>
      </xsl:for-each>
      </TABLE>
  </p></div>
</xsl:template>

<xsl:template match="nfiles">
<div><h4>Number of files in the distribution, after exclusions: <xsl:value-of select="."/></h4></div>
</xsl:template>

<xsl:template match="/srcrpt/licensefiles">
  <div><p>
      <TABLE border="1">
      <tr><th>License Files</th></tr>
      <xsl:for-each select="./licensefile">
          <tr><td><xsl:value-of select="."/></td></tr>
      </xsl:for-each>
      </TABLE>
  </p></div>
</xsl:template>

<xsl:template match="/srcrpt/binaries">
  <div><p>
      <TABLE border="1">
      <tr><th>Files not scanned,
either because Perl detected them as binaries or because they are
encoded in UTF-16</th></tr>
      <xsl:for-each select="./binary">
          <tr><td><xsl:value-of select="."/></td></tr>
      </xsl:for-each>
      </TABLE>
  </p></div>
</xsl:template>

</xsl:stylesheet>
