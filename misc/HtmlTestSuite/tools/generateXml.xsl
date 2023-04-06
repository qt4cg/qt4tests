<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:f="f"
   xmlns:saxon="http://saxon.sf.net/"
   expand-text="yes">
   
   <xsl:param name="repo" select="'file:///Users/mike/GitHub/qt4cg/qt4tests/misc/HtmlTestSuite/files'"/>

   
   <xsl:template name="main">
      <xsl:variable name="all" select="uri-collection($repo || '?select=*.html;recurse=yes')"/>
      <xsl:for-each select="$all">
         <xsl:variable name="content" select="unparsed-text(.)"/>
         <xsl:variable name="doc" select="saxon:parse-html($content)"/>
         <xsl:variable name="name" select="tokenize(., '/')[last()]"/>
         <xsl:result-document href="{replace($name, 'test-(....)\.html', 'result-$1.xml')}" method="xml">
            <xsl:copy-of select="$doc"/>
         </xsl:result-document>
      </xsl:for-each>
   </xsl:template>
 
   
</xsl:transform>