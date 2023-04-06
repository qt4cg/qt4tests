<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:f="f"
   expand-text="yes">
   
   <xsl:param name="repo" select="'file:///Users/mike/GitHub/wpt/'"/>
   <xsl:function name="f:sig" as="xs:string">
      <xsl:param name="in" as="xs:string"/>
      <xsl:variable name="s" as="xs:string">
         <xsl:value-of>
            <xsl:analyze-string select="$in" regex="&lt;[A-Za-z]{{3}}">
               <xsl:matching-substring><xsl:value-of select="."/></xsl:matching-substring>
               <xsl:non-matching-substring/>
            </xsl:analyze-string>
         </xsl:value-of>
      </xsl:variable>
      <xsl:sequence select="$s"/>
   </xsl:function>
   
   <xsl:template name="main">
      <xsl:variable name="all" select="uri-collection($repo || '?select=*.html;recurse=yes')"/>
      <xsl:variable name="files" select="$all ! (if (unparsed-text-available(.)) then unparsed-text(.) else ())" as="xs:string*"/>
      <xsl:for-each-group select="$files" group-by="f:sig(.)">
         <xsl:if test="position() mod 10 = 1">
            <xsl:result-document href="test-{format-integer(position() idiv 10, '0000')}.html" method="text">
               <xsl:value-of select="current-group()[1]"/>
            </xsl:result-document>
         </xsl:if>
      </xsl:for-each-group>
   </xsl:template>
   
   <xsl:template name="stats">
      <out>
         <total><xsl:value-of select="count(uri-collection($repo || '?select=*.html;recurse=yes'))"/></total>
         <distinct><xsl:value-of select="count(distinct-values(uri-collection($repo || '?select=*.html;recurse=yes') ! (if (unparsed-text-available(.)) then unparsed-text(.) else ()) ! f:sig(.))) "/></distinct>
      </out>
   </xsl:template>
   
</xsl:transform>