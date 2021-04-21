<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    exclude-result-prefixes="#all"
    xmlns:xqts="http://www.w3.org/2005/02/query-test-XQTSCatalog"
    xmlns:xquts="http://www.w3.org/2005/02/query-test-update"
    xmlns="http://www.w3.org/2010/09/qt-fots-catalog"
    xmlns:out="http://www.w3.org/2010/09/qt-fots-catalog"
    xmlns:f="http://local/functions"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xpath-default-namespace="http://www.w3.org/2005/02/query-test-update"
    expand-text="yes"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> 2021-04-19</xd:p>
            <xd:p><xd:b>Author:</xd:b> Michael Kay</xd:p>
            <xd:p>Converts a set of XQUTS tests into a set of QT3 tests. Input document is 
            the XQUTS catalog. Result document is a QT3-format catalog (which gets merged
            manually with the existing QT3 test catalog on completion).</xd:p>
        </xd:desc>
    </xd:doc>

    
    <xsl:template match="/">
        <catalog xmlns="http://www.w3.org/2010/09/qt-fots-catalog" test-suite="XQUTS" version="3.1">
            <environment name="empty"/>
            <xsl:for-each select="//test-group[test-case]">
                <xsl:variable name="testSetName" select="'upd-' || translate(@name, ' ', '')"/>
                <test-set name="{$testSetName}" file="upd/{translate(@name, ' ', '')}.xml"/>
                <xsl:result-document href="upd/{translate(@name, ' ', '')}.xml">
                    <test-set name="{$testSetName}">
                        <description>
                            <xsl:value-of select="'XQuery Update', GroupInfo/(title[normalize-space()], description[normalize-space()])" separator=" - "/>
                        </description>
                        <dependency type="spec" value="XQ30+"/>
                        <dependency type="feature" value="XQUpdate"/>
                        <xsl:if test="$testSetName = 'upd-StaticTyping'">
                            <dependency type="feature" value="staticTyping"/>
                        </xsl:if>
                        <xsl:apply-templates select="test-case"/>
                    </test-set>       
                </xsl:result-document>
            </xsl:for-each>
        </catalog>
    </xsl:template>
    
    <!-- the name of the test set to be created, e.g. a function name or syntax production name -->
    <xsl:param name="function" as="xs:string"/>
    
    <!--default assertion to be used -->
    <xsl:param name="assertion" as="xs:string" select="'assert-string-value'"/>
    
    <!-- default prefix -->
    <xsl:param name="prefix" as="xs:string" select="'op'"/>
    <xsl:variable name="kind" as="xs:string"
        select="if ($prefix eq 'fn' or $prefix eq 'map' or $prefix eq 'math') then 'function'
                else if ($prefix eq 'op') then 'operator'
                else if ($prefix eq 'prod') then 'production'
                else if ($prefix eq 'topic') then 'topic'
                else if ($prefix eq 'uc') then 'use-case'
                else ''"/>
    
    <xsl:output method="xml" indent="yes"
        cdata-section-elements="out:assert-xml out:assert out:test out:update"
        saxon:double-space="dependency test-case" xmlns:saxon="http://saxon.sf.net/"/>
    
    <xsl:variable name="main-catalog" select="doc(resolve-uri('../XQTSCatalog.xml', base-uri(.)))"/>
    
    <xsl:variable name="apos">'</xsl:variable>
    <xsl:variable name="escaped-apos">&amp;apos;</xsl:variable>
    
    <xsl:function name="f:raw-query" as="xs:string">
        <xsl:param name="state" as="element(state)"/>
        <xsl:for-each select="$state">
            <xsl:variable name="querytext" select="unparsed-text(resolve-uri(concat('Queries/XQuery/', ../@FilePath, query/@name, '.xq'), base-uri(.)))"/>
            <xsl:sequence select="normalize-space(replace($querytext, '\(:.*?:\)', ''))"/> 
        </xsl:for-each>
    </xsl:function>
    
    <xsl:template match="test-case">
        <xsl:variable name="comments" select="f:comments(f:raw-query(state[1]))[not(normalize-space()=('insert-start', 'insert-end'))]"/>
        <test-case name="{replace(@name, '-([0-9][0-9])$', '-0$1')}">
            <description><xsl:value-of select="string-join((description, $comments), '&#xa;')"/></description>
            <created by="{@Creator}" on="{state[1]/query/@date}"/>
            <modified by="Michael Kay" on="2021-04-18" change="converted from original XQUTS test {@name}"/>
            <environment>
                <xsl:for-each select="state[1]/input-file">
                    <xsl:variable name="id" select="string(.)"/>
                    <xsl:variable name="decl" select="//source[@ID=$id]"/>
                    <source role="${@variable}" 
                            file="{$decl/@FileName}" 
                            mutable="yes" 
                            declared="yes">
                        <xsl:if test="$decl/@schema">
                            <xsl:attribute name="validation">strict</xsl:attribute>
                        </xsl:if>
                    </source>
                    <xsl:if test="$decl/@schema">
                        <xsl:variable name="sch" select="//schema[@ID=$decl/@schema]"/>
                        <schema uri="{$sch/@uri}" file="{$sch/@FileName}"/>
                    </xsl:if>
                </xsl:for-each>
            </environment>
            <xsl:if test="state/input-file/@schema">
                <dependency type="feature" value="schemaImport"/>
            </xsl:if>
            <xsl:for-each select="state">
                <test>
                    <xsl:if test="position() ne last() or ../@scenario = 'runtime-error' 
                        or ./expected-error or not(output-file)">
                        <xsl:attribute name="update">yes</xsl:attribute>
                    </xsl:if>
                    <xsl:variable name="raw" select="f:raw-query(.)"/>
                    <xsl:choose>
                        <xsl:when test="position() = 1">
                            <xsl:sequence select="$raw"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:sequence select="$raw 
                                => replace('declare variable \$input-context external;', '')
                                => replace('\$input-context', '.')"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </test>
            </xsl:for-each>
            <xsl:variable name="last-state" select="state[last()]"/>
            <result>
                <xsl:choose>
                    <xsl:when test="count(state/expected-error) gt 1">
                        <any-of>
                            <xsl:apply-templates select="state/expected-error"/> 
                        </any-of>
                    </xsl:when>
                    <xsl:when test="state/expected-error">
                        <xsl:apply-templates select="state/expected-error"/>  
                    </xsl:when>
                    <xsl:when test="count($last-state/output-file) gt 1">
                        <any-of>
                            <xsl:apply-templates select="$last-state/output-file"/>
                        </any-of>
                    </xsl:when>
                    <xsl:when test="$last-state/output-file">
                        <xsl:apply-templates select="$last-state/output-file"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <assert>$result instance of item()* (: any non-error result is OK :)</assert>
                    </xsl:otherwise>
                </xsl:choose>                    
            </result>
        </test-case>
    </xsl:template>
    
    <xsl:template match="output-file">
        <xsl:variable name="results" select="unparsed-text(resolve-uri(concat('ExpectedTestResults/', ../../@FilePath, .), base-uri(.)))"/>
        <xsl:choose>
            <xsl:when test="$results = ''">
                <assert-empty/>
            </xsl:when>
            <xsl:when test="$results = 'true'">
                <assert-true/>
            </xsl:when>
            <xsl:when test="$results = 'false'">
                <assert-false/>
            </xsl:when>
            <xsl:when test="@compare = ('XML', 'Fragment')">
                <assert-xml>
                    <xsl:value-of select="$results"/>
                </assert-xml>
            </xsl:when>
            <xsl:when test="@compare = 'Text'">
                <assert-string-value>
                    <xsl:value-of select="$results"/>
                </assert-string-value>
            </xsl:when>
            <xsl:otherwise>
                <assert>false() (:unknown comparison requested :)</assert>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="expected-error">
        <error code="{.}"/>       
    </xsl:template>
    
    <xsl:function name="f:comments" as="xs:string*">
        <xsl:param name="query" as="xs:string"/>
        <xsl:analyze-string select="$query" regex="\(:(.*?):\)">
            <xsl:matching-substring>
                <xsl:sequence select="normalize-space(regex-group(1))"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring/>
        </xsl:analyze-string>
    </xsl:function>
    
    <xsl:function name="f:assertion-from-query" as="xs:string*">
        <xsl:param name="query" as="xs:string"/>
        <xsl:variable name="sans-comments" as="xs:string">
            <xsl:value-of>
                <xsl:analyze-string select="$query" regex="\(:(.*?):\)">
                    <xsl:matching-substring/>
                    <xsl:non-matching-substring>
                        <xsl:value-of select="."/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:value-of>
        </xsl:variable>
        <xsl:sequence select="$sans-comments => replace('declare variable \$input-context external;', 'let \$input-context := \$result return ')"/>
    </xsl:function>
    
 
    
</xsl:stylesheet>
