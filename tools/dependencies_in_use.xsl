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
				<xd:li><xd:pre>html</xd:pre>: an HTML page containing a table that lists all the variations of <xd:pre>dependency</xd:pre> in use within this test suite (default)</xd:li>
				<xd:li><xd:pre>type-table</xd:pre>: just the table from the HTML page</xd:li>
				<xd:li><xd:pre>type-list</xd:pre>: a list of the distinct dependency types actually in use</xd:li>
				<xd:li><xd:pre>defined-type-list</xd:pre>: a list of the permitted dependency types defined in catalog-schema.xsd</xd:li>
				<xd:li><xd:pre>feature-list</xd:pre>: a list of the distinct values used when <xd:pre>dependency/@type = 'feature'</xd:pre>, sorted alphabetically (case insensitive).</xd:li>
				<xd:li><xd:pre>feature-table</xd:pre>: a table view of the distinct values used when <xd:pre>dependency/@type = 'feature'</xd:pre>, including a description (where available) of each feature value; sorted alphabetically (case insensitive).</xd:li>
				<xd:li><xd:pre>data</xd:pre>: just the summarised data that the HTML page and table are generated from</xd:li>
			</xd:ul>
		</xd:desc>
	</xd:doc>
	<xsl:param name="output" select="'html'" as="xs:string" static="true" />
	
	
	<xsl:output method="xml" indent="true" omit-xml-declaration="false" use-when="$output = 'data'" />
	<xsl:output method="xml" indent="true" omit-xml-declaration="true" use-when="$output = ('type-table', 'type-list', 'defined-type-list', 'feature-list', 'feature-table')" suppress-indentation="p li pre" />
	<xsl:output method="xhtml" html-version="5" indent="true" omit-xml-declaration="true" use-when="$output = 'html'" />


	<xd:doc scope="component">
		<xd:desc>Make a note of where the input catalog file is, so it can be used to help resolve other URIs later.</xd:desc>
	</xd:doc>
	<xsl:variable name="catalog-uri" select="base-uri(/)" as="xs:anyURI" />
	
	<xd:doc scope="component">
		<xd:desc>Generates the outer HTML shell when outputing an HTML page.</xd:desc>
	</xd:doc>
	<xsl:template match="/" use-when="$output = 'html'">	
		<html>
			<head>
				<title>List of Dependency Values in Use | QT4CG XPath &amp; XQuery Test Suite</title>
				<style>
					table {{
						border-collapse: collapse;
					}}
					th, td {{
						padding: .25em .5em;
						border: 1px solid black;
					}}
					th {{
						background-color: black;
						color: white;
					}}
					.type, .value {{
						text-align: left;
					}}
					.satisfied {{
						text-align: center;
					}}
					.total-tests {{
						text-align: right;
					}}				
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
					<h1>List of Dependency Values in Use</h1>
				</div>
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
					<xsl:for-each-group select="$occurrences" group-by="@type">
						<xsl:sort select="fots:count-tests-with-dependency(current-group())" data-type="number" order="descending" />
						<xsl:sort select="current-grouping-key()" data-type="text" order="ascending" />
						
						<dependency type="{current-grouping-key()}">							
							<xsl:for-each-group select="current-group()" group-by="@value">
								<xsl:sort select="fots:count-tests-with-dependency(current-group())" data-type="number" order="descending" />
								<xsl:sort select="current-grouping-key()" data-type="text" order="ascending" />
								
								<value name="{current-grouping-key()}">																	
									<xsl:for-each-group select="current-group()" group-by="if (normalize-space(@satisfied) = '') then 'true' else @satisfied">
										<xsl:sort select="fots:count-tests-with-dependency(current-group())" data-type="number" order="descending" />
										<xsl:sort select="current-grouping-key()" data-type="text" order="ascending" />
										
										<satisfied total-tests-affected="{fots:count-tests-with-dependency(current-group())}">{current-grouping-key()}</satisfied>
										
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
			<xsl:when test="$output = 'feature-table'">
				<xsl:apply-templates select="$data/dependencies/dependency[@type = 'feature']" mode="feature-table" />
			</xsl:when>
			<xsl:when test="ends-with($output, '-list')">
				<xsl:apply-templates select="$data/dependencies" use-when="$output = 'type-list'" mode="type-list" />
				<xsl:apply-templates select="$data/dependencies" use-when="$output = 'defined-type-list'" mode="defined-type-list">
					<xsl:with-param name="data" select="$data" as="document-node()" />
				</xsl:apply-templates>
				<xsl:apply-templates select="$data/dependencies/dependency[@type = 'feature']" use-when="$output = 'feature-list'" mode="feature-list" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="$data/dependencies" />
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>
	
	
	<xd:doc scope="component">
		<xd:desc>Create a list of all the distinct values of dependency/@type (dependency types actually in use).</xd:desc>
	</xd:doc>
	<xsl:template match="/dependencies" mode="type-list">
		<xsl:choose>
			<xsl:when test="count(*) = 0">
				<p><i>None found.</i></p>
			</xsl:when>
			<xsl:otherwise>
				<ul>
					<xsl:comment> Generated by using tools/dependencies_in_use.xsl to transform catalog.xml with the $output param set to 'type-list' </xsl:comment>
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
		<xsl:choose>
			<xsl:when test="count($defined-types) = 0">
				<p><i>None found.</i></p>
			</xsl:when>
			<xsl:otherwise>
				<ul>
					<xsl:comment> Generated by using tools/dependencies_in_use.xsl to transform catalog.xml with the $output param set to '{$output}' </xsl:comment>
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
		<xsl:choose>
			<xsl:when test="count(*) = 0">
				<p><i>None found.</i></p>
			</xsl:when>
			<xsl:otherwise>
				<ul>
					<xsl:comment> Generated by using tools/dependencies_in_use.xsl to transform catalog.xml with the $output param set to 'feature-list' </xsl:comment>
					<xsl:for-each select="value">
						<xsl:sort select="lower-case(@name)" data-type="text" order="ascending" />
						<li>{@name}</li>
					</xsl:for-each>
				</ul>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xd:doc scope="component">
		<xd:desc>Create a table view of all the distinct values of dependency[@type = 'feature']/@value.</xd:desc>
	</xd:doc>
	<xsl:template match="/dependencies/dependency[@type = 'feature']" mode="feature-table">
		<xsl:choose>
			<xsl:when test="count(*) = 0">
				<p><i>None found.</i></p>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="dependency-meanings" select="doc(resolve-uri('dependency_meanings.xml', $catalog-uri))/*" as="element()" />
				<table>
					<xsl:comment> Generated by using tools/dependencies_in_use.xsl to transform catalog.xml with the $output param set to 'feature-table' </xsl:comment>
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
									<xsl:copy-of select="$dependency-meanings/dependency[@type = 'feature']/value[@name = current()/@name]/description/*" />
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
	<xsl:template match="/dependencies">
		<xsl:choose>
			<xsl:when test="count(*) = 0">
				<p><i>None found.</i></p>
			</xsl:when>
			<xsl:otherwise>
				<table>
					<xsl:attribute name="style" use-when="$output = 'type-table'" select="'border-collapse: collapse;'" />
					<xsl:comment> Generated by using tools/dependencies_in_use.xsl to transform catalog.xml with the $output param set to '{$output}' </xsl:comment>
					<thead>
						<tr>
							<th class="type">
								<xsl:attribute name="style" use-when="$output = 'type-table'" select="'padding: .25em .5em; border: 1px solid black; text-align: left; background-color: black; color: white;'" />
								<xsl:text>Type</xsl:text>
							</th>
							<th class="value">
								<xsl:attribute name="style" use-when="$output = 'type-table'" select="'padding: .25em .5em; border: 1px solid black; text-align: left; background-color: black; color: white;'" />
								<xsl:text>Value</xsl:text>
							</th>
							<th class="satisfied">
								<xsl:attribute name="style" use-when="$output = 'type-table'" select="'padding: .25em .5em; border: 1px solid black; text-align: center; background-color: black; color: white;'" />
								<xsl:text>Satisfied</xsl:text>
							</th>
							<th class="total-tests">
								<xsl:attribute name="style" use-when="$output = 'type-table'" select="'padding: .25em .5em; border: 1px solid black; text-align: right; background-color: black; color: white;'" />
								<xsl:text>Total Tests Affected</xsl:text>
							</th>
						</tr>
					</thead>
					<tbody>
						<xsl:apply-templates />
					</tbody>
				</table>		
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xd:doc scope="component">
		<xd:desc>Parameterise information about this dependency type that will be used later but is easy to gather now.</xd:desc>
	</xd:doc>
	<xsl:template match="dependency">
		<xsl:apply-templates>
			<xsl:with-param name="odd-type" select="position() mod 2 != 0" as="xs:boolean" tunnel="true" />			
		</xsl:apply-templates>
	</xsl:template>
	
	
	<xd:doc scope="component">
		<xd:desc>Parameterise information about this value that will be used later but is easy to gather now.</xd:desc>
	</xd:doc>
	<xsl:template match="value">
		<xsl:apply-templates>
			<xsl:with-param name="odd-value" select="position() mod 2 != 0" as="xs:boolean" tunnel="true" />
			<xsl:with-param name="start-new-type" select="position() = 1" as="xs:boolean" tunnel="true" />
		</xsl:apply-templates>
	</xsl:template>
	
	
	<xd:doc scope="component">
		<xd:desc>Create a row in the table.</xd:desc>
		<xd:param name="odd-type">True if the ancestor <xd:pre>dependency</xd:pre> element is in an odd position within the full set of dependencies; false if it's in an even position.</xd:param>
		<xd:param name="odd-value">True if the parent <xd:pre>value</xd:pre> element is in an odd position within its parent dependency type; false if it's in an even position.</xd:param>
		<xd:param name="start-new-type">True if the parent <xd:pre>value</xd:pre> element is the first within its parent dependency type; false if it's not.</xd:param>
	</xd:doc>
	<xsl:template match="satisfied">
		<xsl:param name="odd-type" as="xs:boolean" tunnel="true" />
		<xsl:param name="odd-value" as="xs:boolean" tunnel="true" />
		<xsl:param name="start-new-type" as="xs:boolean" tunnel="true" />
		
		<xsl:variable name="odd-satisfied" select="position() mod 2 != 0" as="xs:boolean" />
		<xsl:variable name="total-rows-in-this-type" select="ancestor::dependency[1]/count(descendant::satisfied)" as="xs:integer" />
		<xsl:variable name="total-rows-in-this-value" select="ancestor::value[1]/count(descendant::satisfied)" as="xs:integer" />
				
		<xsl:variable name="odd-rgb" select="'255, 255, 0'" as="xs:string" />
		<xsl:variable name="even-rgb" select="'255, 230, 0'" as="xs:string" />
		
		<xsl:variable name="type-bg" select="concat('rgba(', if ($odd-type) then $odd-rgb else $even-rgb, ', .65)')" as="xs:string" />
		<xsl:variable name="value-bg" select="if ($odd-value) then $type-bg else concat('rgba(', if ($odd-type) then $odd-rgb else $even-rgb, ', .3)')" as="xs:string" />
		<xsl:variable name="satisfied-bg" select="
			if ($odd-value) 
			then (
				if ($odd-satisfied) 
				then $type-bg
				else concat('rgba(', if ($odd-type) then $odd-rgb else $even-rgb, ', .5)')
			)
			else (
				if ($odd-satisfied) 
				then $value-bg 
				else concat('rgba(', if ($odd-type) then $odd-rgb else $even-rgb, ', .2)')
			)" as="xs:string" />
		
		<tr>
			<xsl:if test="$start-new-type and position() = 1">
				<td class="type" style="background-color: {$type-bg};{if ($output = 'type-table') then ' padding: .25em .5em; border: 1px solid black; text-align: left;' else ()}">
					<xsl:if test="$total-rows-in-this-type > 1">
						<xsl:attribute name="rowspan" select="$total-rows-in-this-type" />
					</xsl:if>
					<xsl:text>{ancestor::dependency/@type}</xsl:text>
				</td>
			</xsl:if>
			<xsl:if test="position() = 1">
				<td class="value" style="background-color: {$value-bg};{if ($output = 'type-table') then ' padding: .25em .5em; border: 1px solid black; text-align: left;' else ()}">
					<xsl:if test="$total-rows-in-this-value > 1">
						<xsl:attribute name="rowspan" select="$total-rows-in-this-value" />
					</xsl:if>
					<xsl:text>{parent::value/@name}</xsl:text>
				</td>
			</xsl:if>			
			<td class="satisfied" style="background-color: {$satisfied-bg};{if ($output = 'type-table') then ' padding: .25em .5em; border: 1px solid black; text-align: center;' else ()}">{.}</td>
			<td class="total-tests" style="background-color: {$satisfied-bg};{if ($output = 'type-table') then ' padding: .25em .5em; border: 1px solid black; text-align: right;' else ()}">{@total-tests-affected}</td>
		</tr>
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

		
</xsl:stylesheet>