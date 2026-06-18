<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
	xmlns:fots="http://www.w3.org/2010/09/qt-fots-catalog"
	xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:math="http://www.w3.org/2005/xpath-functions/math"
	exclude-result-prefixes="xs math fots xd"
	version="3.0"
    expand-text="true">
	
	<xd:doc scope="stylesheet">
		<xd:desc>
			<xd:p>Lists all the variations of the <xd:pre>dependency</xd:pre> element in use within this test suite, broken down by:</xd:p>
			<xd:ul>
				<xd:li>type</xd:li>
				<xd:li>value</xd:li>
				<xd:li>satisfied (true/false)</xd:li>
			</xd:ul>
			<xd:p>Includes a count of the total number of tests affected by each variation of <xd:pre>dependency</xd:pre>.</xd:p>
			<xd:p>Can also generate other views of the same data, for inclusion in guide/running.html.</xd:p>
			<xd:p>Input: <xd:pre>catalog.xml</xd:pre> (found in the root of this project)</xd:p>
			<xd:p>Output: Depends on the value of the global <xd:pre>$output</xd:pre> parameter.</xd:p>
			<xd:p><xd:b>Created on:</xd:b> 12 June 2026</xd:p>
			<xd:p><xd:b>Author:</xd:b> Sheila Thomson</xd:p>
		</xd:desc>
	</xd:doc>
	
	
	<xd:doc scope="component">
		<xd:desc>
			<xd:p>Controls what is generated and returned by this stylesheet:</xd:p>
			<xd:ul>
				<xd:li><xd:pre>one-pager</xd:pre>: (default) an HTML page containing the defined-type-list, feature-list and type-table</xd:li>
				<xd:li><xd:pre>type-table</xd:pre>: a table that lists all the variations of <xd:pre>dependency</xd:pre> in use within this test suite</xd:li>
				<xd:li><xd:pre>type-list</xd:pre>: a list of the distinct dependency types actually in use</xd:li>
				<xd:li><xd:pre>defined-type-list</xd:pre>: a list of the permitted dependency types defined in catalog-schema.xsd</xd:li>
				<xd:li><xd:pre>feature-list</xd:pre>: a list of the distinct values used when <xd:pre>dependency/@type = 'feature'</xd:pre>, sorted alphabetically (case insensitive).</xd:li>
				<xd:li><xd:pre>feature-table</xd:pre>: a table view of the distinct values used when <xd:pre>dependency/@type = 'feature'</xd:pre>, including a description (where available) of each feature value; sorted alphabetically (case insensitive).</xd:li>
				<xd:li><xd:pre>data</xd:pre>: just the summarised data that the HTML page and table are generated from</xd:li>
			</xd:ul>
		</xd:desc>
	</xd:doc>
	<xsl:param name="output" select="'one-pager'" as="xs:string" static="true" />
	
	<xsl:output method="xml" indent="true" omit-xml-declaration="false" use-when="$output = 'data'" />
	<xsl:output method="xml" indent="true" omit-xml-declaration="true" use-when="$output = ('type-table', 'type-list', 'defined-type-list', 'feature-list', 'feature-table')" suppress-indentation="p li pre" />
	<xsl:output method="xhtml" html-version="5" indent="true" omit-xml-declaration="true" use-when="$output = 'one-pager'" />


	<xd:doc scope="component">
		<xd:desc>Make a note of where the input catalog file is, so it can be used to help resolve relative URIs.</xd:desc>
	</xd:doc>
	<xsl:variable name="catalog-uri" select="base-uri(/)" as="xs:anyURI" />
	
	<xsl:variable name="dependency-meanings" select="doc(resolve-uri('dependency_meanings.xml', $catalog-uri))/*" as="element()" />
	
	<xd:doc scope="component">
		<xd:desc>Generates the outer HTML shell when outputing an HTML page.</xd:desc>
	</xd:doc>
	<xsl:template match="/" use-when="$output = 'one-pager'">	
		<html>
			<head>
				<title>List of Dependency Values in Use | QT4CG XPath &amp; XQuery Test Suite</title>
				<style>
					.titles p {{
						margin-bottom: 0;
					}}
					.titles h1 {{
						margin-top: 0;
					}}
				</style>
			</head>
			<body>
				<div class="titles">
					<p>QT4CG XPath &amp; XQuery Test Suite</p>
					<h1>Dependency Metadata</h1>
				</div>
				<ol id="toc">
					<li><a href="#defined-types-list">List of Defined Dependency Types</a></li>
					<li><a href="#feature-values-list">List of Feature Dependency Type Values in Use</a></li>
					<li><a href="#types-in-use-table">Table of Dependency Types and Values In Use</a></li>					
				</ol>
				<xsl:apply-templates />
			</body>
		</html>				
	</xsl:template>	
	
	
	<xd:doc scope="component">
		<xd:desc>Collect and summarise the dependencies data.</xd:desc>
	</xd:doc>
	<xsl:template match="/fots:catalog">		
		
		<xsl:variable name="occurrences" as="element()*">
			<xsl:for-each select="fots:test-set/@file">
				<xsl:sequence select="doc(resolve-uri(., $catalog-uri))//fots:dependency" />
			</xsl:for-each>	
		</xsl:variable>
		
		<xsl:variable name="data" as="document-node()">
			<xsl:document>
				<dependencies>		
					<xsl:call-template name="provenance-comment" />
					<xsl:for-each-group select="$occurrences" group-by="@type">
						<xsl:sort select="fots:count-tests-with-dependency(current-group())" data-type="number" order="descending" />
						<xsl:sort select="current-grouping-key()" data-type="text" order="ascending" />
						
						<xsl:variable name="type-id" select="current-grouping-key()" as="xs:string?" />
						<dependency type="{$type-id}">						
							<xsl:copy-of select="$dependency-meanings/dependency[@type = $type-id]/description" />
							
							<xsl:for-each-group select="current-group()" group-by="fots:sort-value-tokens(@value)">
								<xsl:sort select="fots:count-tests-with-dependency(current-group())" data-type="number" order="descending" />
								<xsl:sort select="current-grouping-key()" data-type="text" order="ascending" />
																
								<value name="{current-grouping-key()}">	
									<xsl:copy-of select="$dependency-meanings/dependency[@type = $type-id]/value[fots:sort-value-tokens(@name) = current-grouping-key()]/description" />
									
									<xsl:for-each-group select="current-group()" group-by="if (normalize-space(@satisfied) = '') then 'true' else @satisfied">
										<xsl:sort select="fots:count-tests-with-dependency(current-group())" data-type="number" order="descending" />
										<xsl:sort select="current-grouping-key()" data-type="text" order="ascending" />
																				
										<satisfied value="{current-grouping-key()}" total-tests-affected="{fots:count-tests-with-dependency(current-group())}">
											<permutations>
												<xsl:for-each-group select="current-group()" group-by="@value">
													<xsl:sort select="fots:count-tests-with-dependency(current-group())" data-type="number" order="descending" />
													<xsl:sort select="current-grouping-key()" data-type="text" order="ascending" />
													
													<dependency type="{$type-id}" value="{current-grouping-key()}" total-tests-affected="{fots:count-tests-with-dependency(current-group())}" />
												</xsl:for-each-group>											
											</permutations>
										</satisfied>
										
									</xsl:for-each-group>									
								</value>													
							</xsl:for-each-group>							
						</dependency>						
					</xsl:for-each-group>	
				</dependencies>
			</xsl:document>
		</xsl:variable>
		
		<xsl:choose>
			<xsl:when test="$output = 'data'">
				<xsl:copy-of select="$data" />
			</xsl:when>
			<xsl:otherwise>
				<!-- Unused in docs but handy if you just want a simple, alphabetical list of the distinct type values in use (will include any types used but not defined in catalog-schema.xsd) -->
				<xsl:apply-templates select="$data/dependencies" mode="type-list" use-when="$output = 'type-list'" />
				<!-- Added to guide/running.html, June 2026 -->
				<xsl:apply-templates select="$data/dependencies" mode="defined-type-list" use-when="$output = ('defined-type-list', 'one-pager')">
					<xsl:with-param name="data" select="$data" as="document-node()" />
				</xsl:apply-templates>
				<!-- Unused in docs but handy if you just want a simple, alphabetical list of the values in use when dependency/@type = 'feature' -->
				<xsl:apply-templates select="$data/dependencies/dependency[@type = 'feature']" mode="feature-list" use-when="$output = ('feature-list', 'one-pager')"  />
				<!-- Replaced the feature-table in guide/running.html, June 2026 -->
				<xsl:apply-templates select="$data/dependencies" mode="type-table" use-when="$output = ('type-table', 'one-pager')" />
				<!-- Used in guide/running.html prior to June 2026 (unstyled) -->
				<xsl:apply-templates select="$data/dependencies/dependency[@type = 'feature']" mode="feature-table" use-when="$output = 'feature-table'" />
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>
	
	
	<xd:doc scope="component">
		<xd:desc>Create a list of all the distinct values of dependency/@type (dependency types actually in use).</xd:desc>
	</xd:doc>
	<xsl:template match="/dependencies" mode="type-list">
		<xsl:if test="$output = 'one-pager'">
			<h2 id="types-in-use-list">List of Types in Use</h2>
			<div class="intro">
				<p>All the distinct values currently found in <code>dependency/@type</code>; sorted alphabetically (case insensitive).</p>
			</div>
		</xsl:if>
		<xsl:choose>
			<xsl:when test="count(*) = 0">
				<p><i>None found.</i></p>
			</xsl:when>
			<xsl:otherwise>
				<ul>
					<xsl:call-template name="provenance-comment" />
					<xsl:for-each select="dependency">
						<xsl:sort select="lower-case(@type)" data-type="text" order="ascending" />
						<li>{@type}</li>
					</xsl:for-each>
				</ul>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xd:doc scope="component">
		<xd:desc>Create a list of all the permitted dependency types, as defined in catalog.xsd.</xd:desc>
		<xd:param name="data">The data already collected about dependencies in use.</xd:param>
	</xd:doc>
	<xsl:template match="/dependencies" mode="defined-type-list">
		<xsl:param name="data" select="parent::document-node()" as="document-node()" />
		
		<xsl:variable name="catalog-schema" select="doc(resolve-uri('catalog-schema.xsd', $catalog-uri))" as="document-node()" />
		<xsl:variable name="defined-types" select="$catalog-schema/xs:schema/xs:simpleType[@name =  'dependencyEnumType']/descendant::xs:enumeration" as="element()*" />

		<xsl:if test="$output = 'one-pager'">
			<h2 id="types-defined-list">List of Defined Dependency Types</h2>
			<div class="intro">
				<p>All types defined in <code>qt4tests/catalog-schema.xsd</code>; sorted alphabetically (case-insensitive).</p>
			</div>
		</xsl:if>
		<xsl:choose>
			<xsl:when test="count($defined-types) = 0">
				<p><i>None found.</i></p>
			</xsl:when>
			<xsl:otherwise>
				<ul>
					<xsl:call-template name="provenance-comment" />
					<xsl:for-each select="$defined-types/@value">
						<xsl:sort select="lower-case(.)" data-type="text" order="ascending" />
						<li>
							<xsl:text>{.}</xsl:text>
							<xsl:if test="not($data/*/dependency/@type = .)"><xsl:text> </xsl:text><i>(not currently applied to any tests)</i></xsl:if>
						</li>
					</xsl:for-each>
				</ul>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xd:doc scope="component">
		<xd:desc>Create a list of all the distinct values of dependency[@type = 'feature']/@value.</xd:desc>
	</xd:doc>
	<xsl:template match="/dependencies/dependency[@type = 'feature']" mode="feature-list">
		<xsl:if test="$output = 'one-pager'">
			<h2 id="feature-values-list">List of Feature Dependency Type Values In Use</h2>
			<div class="intro">
				<p>All distinct values in <code>dependency[@type = 'feature']/@value</code>; sorted alphabetically (case insensitive).</p>
			</div>
		</xsl:if>
		<xsl:choose>
			<xsl:when test="count(*) = 0">
				<p><i>None found.</i></p>
			</xsl:when>
			<xsl:otherwise>
				<ul>
					<xsl:call-template name="provenance-comment" />
					<xsl:for-each select="value">
						<xsl:sort select="lower-case(@name)" data-type="text" order="ascending" />
						<li>{@name}</li>
					</xsl:for-each>
				</ul>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xd:doc scope="component">
		<xd:desc>Create an HTML table view of all the distinct values of dependency[@type = 'feature']/@value.</xd:desc>
	</xd:doc>
	<xsl:template match="/dependencies/dependency[@type = 'feature']" mode="feature-table">
		<xsl:if test="$output = 'one-pager'">
			<h2 id="feature-values-table">Table of Feature Dependency Type Values In Use</h2>
			<div class="intro">
				<p>All distinct values in <code>dependency[@type = 'feature']/@value</code>, the number of tests affected and intended effect of the dependency; sorted alphabetically (case insensitive).</p>
			</div>
		</xsl:if>
		<xsl:choose>
			<xsl:when test="count(*) = 0">
				<p><i>None found.</i></p>
			</xsl:when>
			<xsl:otherwise>				
				<table>
					<xsl:call-template name="provenance-comment" />
					<thead>
						<tr>
							<th style="vertical-align: bottom; text-align: left; border-bottom: 1px solid silver;"><p>Feature name</p></th>
							<th style="vertical-align: bottom; text-align: center; border-bottom: 1px solid silver;"><p>Approx number of tests</p></th>
							<th style="vertical-align: bottom; text-align: left; border-bottom: 1px solid silver;"><p>Meaning</p></th>
						</tr>
					</thead>
					<tbody>
						<xsl:for-each select="value">
							<xsl:sort select="lower-case(@name)" data-type="text" order="ascending" />
							<tr>
								<td style="vertical-align: top; text-align: left; border-bottom: 1px solid silver;"><p>{@name}</p></td>
								<td style="vertical-align: top; text-align: right; padding-right: 1em; border-bottom: 1px solid silver;"><p>{sum(satisfied/@total-tests-affected)}</p></td>
								<td style="vertical-align: top; text-align: left; border-bottom: 1px solid silver;">
									<xsl:copy-of select="description/*" />
								</td>
							</tr>
						</xsl:for-each>
					</tbody>
				</table>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xd:doc scope="component">
		<xd:desc>Create an HTML table view of the dependencies data.</xd:desc>
	</xd:doc>
	<xsl:template match="/dependencies" mode="type-table">
		<xsl:if test="$output = 'one-pager'">
			<h2 id="types-in-use-table">Table of Dependency Types and Values In Use</h2>
			<div class="intro">
				<p>All distinct types and values set on <code>dependency</code> elements and whether the dependency must/must not be satisfied; sorted by the number of tests affected, in descending order.</p>
			</div>
		</xsl:if>
		<xsl:choose>
			<xsl:when test="count(*) = 0">
				<p><i>None found.</i></p>
			</xsl:when>
			<xsl:otherwise>
				<table style="border-collapse: collapse;">
					<xsl:call-template name="provenance-comment" />
					<thead>
						<tr>
							<th style="padding: 0 1em; border-bottom: 1px solid black; text-align: left; vertical-align: bottom;"><p style="margin: .5em 0;">Type</p></th>
							<th style="padding: 0 1em; border-bottom: 1px solid black; text-align: left; vertical-align: bottom;"><p style="margin: .5em 0;">Value<sup>*</sup></p></th>
							<th style="padding: 0 1em; border-bottom: 1px solid black; text-align: center; vertical-align: bottom;"><p style="margin: .5em 0;">Satisfied</p></th>
							<th style="padding: 0 1em; border-bottom: 1px solid black; text-align: right; vertical-align: bottom;"><p style="margin: .5em 0;">Total Tests Affected</p></th>
						</tr>
					</thead>
					<tbody>
						<xsl:apply-templates select="dependency" mode="#current" />
					</tbody>
				</table>		
				<p style="font-size: small; font-style: italic;"><sup>*</sup> Some values contain a sequence of space-separated tokens. When creating this table, to reduce duplication, the tokens in such sequences have been sorted.  To see a full list of permutations, transform <code>catalog.xml</code> using <code>tools/dependencies_in_use.xsl</code> with the <code>$output</code> parameter set to <code>data</code>.</p>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xd:doc scope="component">
		<xd:desc>Parameterise information about this dependency type that will be used later but is easy to gather now.</xd:desc>
	</xd:doc>
	<xsl:template match="dependency" mode="type-table">
		<xsl:apply-templates select="value" mode="#current">
			<xsl:with-param name="odd-type" select="position() mod 2 != 0" as="xs:boolean" tunnel="true" />	
		</xsl:apply-templates>
	</xsl:template>
	
	
	<xd:doc scope="component">
		<xd:desc>Parameterise information about this value that will be used later but is easy to gather now.</xd:desc>
	</xd:doc>
	<xsl:template match="value" mode="type-table">
		<xsl:apply-templates select="satisfied" mode="#current">
			<xsl:with-param name="odd-value" select="position() mod 2 != 0" as="xs:boolean" tunnel="true" />
			<xsl:with-param name="end-of-type" select="position() = last()" as="xs:boolean" tunnel="true" />
			<xsl:with-param name="start-new-type" select="position() = 1" as="xs:boolean" tunnel="true" />
		</xsl:apply-templates>
	</xsl:template>
	
	
	<xd:doc scope="component">
		<xd:desc>Create a row in the table.</xd:desc>
		<xd:param name="odd-type">True if the ancestor <xd:pre>dependency</xd:pre> element is in an odd position within the full set of dependencies; false if it's in an even position.</xd:param>
		<xd:param name="odd-value">True if the parent <xd:pre>value</xd:pre> element is in an odd position within its parent dependency type; false if it's in an even position.</xd:param>
		<xd:param name="start-new-type">True if the parent <xd:pre>value</xd:pre> element is the first within its parent dependency type; false if it's not.</xd:param>
	</xd:doc>
	<xsl:template match="satisfied" mode="type-table">
		<xsl:param name="odd-type" as="xs:boolean" tunnel="true" />
		<xsl:param name="odd-value" as="xs:boolean" tunnel="true" />
		<xsl:param name="end-of-type" as="xs:boolean" tunnel="true" />
		<xsl:param name="start-new-type" as="xs:boolean" tunnel="true" />
		
		<xsl:variable name="odd-satisfied" select="position() mod 2 != 0" as="xs:boolean" />
		<xsl:variable name="total-rows-in-this-type" select="ancestor::dependency[1]/count(descendant::satisfied)" as="xs:integer" />
		<xsl:variable name="total-rows-in-this-value" select="ancestor::value[1]/count(descendant::satisfied)" as="xs:integer" />
		<xsl:variable name="border-color" select="if ($end-of-type) then 'black' else 'silver'" as="xs:string" />
		
		<tr>
			<xsl:if test="$start-new-type and position() = 1">
				<td style="padding: 0 1em; border-bottom: 1px solid black; text-align: left; vertical-align: top;">
					<xsl:if test="$total-rows-in-this-type > 1">
						<xsl:attribute name="rowspan" select="$total-rows-in-this-type" />
					</xsl:if>
					<h3 style="margin: .5em 0;">{ancestor::dependency[1]/@type}</h3>
					<xsl:apply-templates select="ancestor::dependency[1]/description" />
				</td>
			</xsl:if>
			<xsl:if test="position() = 1">
				<td style="padding: 0 1em; border-bottom: 1px solid {$border-color}; text-align: left; vertical-align: top;">
					<xsl:if test="$total-rows-in-this-value > 1">
						<xsl:attribute name="rowspan" select="$total-rows-in-this-value" />
					</xsl:if>
					<h4 style="margin: .5em 0;">{parent::value/@name}</h4>
					<xsl:apply-templates select="parent::value/description" />
				</td>
			</xsl:if>			
			<td style="padding: 0 1em; border-bottom: 1px solid {$border-color}; text-align: center; vertical-align: top;">
				<p style="margin: .5em 0;">{@value}</p>
			</td>
			<td style="padding: 0 1em; border-bottom: 1px solid {$border-color}; text-align: right; vertical-align: top;">
				<p style="margin: .5em 0;">{@total-tests-affected}</p>
			</td>
		</tr>
	</xsl:template>
	
	
	<xsl:template match="dependency/description | value/description">
		<div class="description">
			<xsl:apply-templates mode="html" />
		</div>
	</xsl:template>
	
	<xsl:template match="p | li" mode="html" use-when="ends-with($output, '-table')">
		<xsl:copy>
			<xsl:attribute name="style" select="'margin: .5em 0;'" />
			<xsl:apply-templates select="attribute(), node()" mode="#current" />
		</xsl:copy>
	</xsl:template>
	
	
	<xsl:template match="node()" mode="html">
		<xsl:copy>
			<xsl:apply-templates select="attribute(), node()" mode="#current" />
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="attribute()" mode="html">
		<xsl:copy-of select="self::attribute()" />
	</xsl:template>
	
	
	<xsl:template name="provenance-comment">
		<xsl:comment> Updated {current-date()} using tools/dependencies_in_use.xsl to transform catalog.xml with the $output param set to '{$output}' </xsl:comment>
	</xsl:template>
		
	
	<xd:doc scope="component">
		<xd:desc>Find all the tests affected by the specified dependency element.</xd:desc>
		<xd:param name="dependency">A dependency element, in a fots:test-set.</xd:param>
		<xd:return>A sequence of all the tests affected by the specified dependency element.</xd:return>
	</xd:doc>
	<xsl:function name="fots:get-tests-with-dependency" as="element()*">
		<xsl:param name="dependency" as="element()" />
		
		<xsl:sequence select="$dependency/parent::fots:test-case, $dependency/parent::fots:test-set/fots:test-case" />
	</xsl:function>
	
	
	<xd:doc scope="component">
		<xd:desc>Count all the tests affected by the specified dependency element.</xd:desc>
		<xd:param name="dependency">One or more dependency elements, in fots:test-sets.</xd:param>
		<xd:return>The total number of tests affected by the specified dependency elements.</xd:return>
	</xd:doc>
	<xsl:function name="fots:count-tests-with-dependency" as="xs:integer">
		<xsl:param name="dependency" as="element()+" />
		
		<xsl:sequence select="count($dependency/fots:get-tests-with-dependency(self::fots:dependency))" />
	</xsl:function>
	
	
	<xd:doc scope="component">
		<xd:desc>Sort the space separated tokens in a value to reduce duplication caused by the tokens being entered in a different order.</xd:desc>
		<xd:param name="dependency">A sequence of zero to many space separated string tokens.</xd:param>
		<xd:return>The same tokens, sorted.</xd:return>
	</xd:doc>
	<xsl:function name="fots:sort-value-tokens" as="xs:string?">
		<xsl:param name="value" as="xs:string?" />
		
		<xsl:sequence select="if ($value = () or not(contains($value, ' '))) then $value else string-join(sort(tokenize($value, ' ')), ' ')" />
	</xsl:function>

		
</xsl:stylesheet>