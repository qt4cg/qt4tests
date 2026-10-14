<?xml version="1.0" encoding="UTF-8"?>
<sch:schema 
	xmlns:fots="http://www.w3.org/2010/09/qt-fots-catalog"
	xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt3"
	xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
	xmlns:xs="http://www.w3.org/2001/XMLSchema">
	
	<sch:ns prefix="fots" uri="http://www.w3.org/2010/09/qt-fots-catalog" />

	<sch:pattern id="dependency-types">
		
		<sch:rule context="dependency">
			
			<sch:assert test="@type">Missing type attribute.  A dependency element must include a type attribute.</sch:assert>
			<sch:assert test="@type = doc('catalog-schema.xsd')/xs:schema/xs:simpleType[@name =  'dependencyEnumType']/descendant::xs:enumeration/@value">Invalid dependency type.  The value of dependency/@type must match an xs:enumeration/@value for dependencyEnumType, defined in catalog-schema.xsd.</sch:assert>

		</sch:rule>
		
	</sch:pattern>
	
	
	<sch:pattern id="descriptions">
		
		<sch:rule context="dependency">
			
			<sch:assert test="description or value/description">Missing description.  Add a description for either the dependency in general or for each of its listed values.</sch:assert>
			
		</sch:rule>
		
		<sch:rule context="dependency/value">
			
			<sch:assert test="description">Missing description.  Add a description for this value.</sch:assert>
			
		</sch:rule>
		
		<sch:rule context="description">
			
			<sch:assert test="normalize-space(.) != ''">Empty description.</sch:assert>
			
		</sch:rule>
		
	</sch:pattern>
	
	
	<sch:pattern id="dependencies-in-use-content-model">
		
		<sch:rule context="fots:dependency">
			
			<sch:assert test="@type = doc('catalog-schema.xsd')/xs:schema/xs:simpleType[@name =  'dependencyEnumType']/descendant::xs:enumeration/@value">Unexpected dependency type: '<sch:value-of select="@type" />'.  If it's new, please add it to catalog-schema.xsd.  See also guide/running.html.</sch:assert>
			
			<sch:report test="self::*[@type = 'feature']/not(@value = doc('dependency_meanings.xml')/dependency-meanings/dependency[@type = 'feature']/value/@name)">Unexpected feature dependency value: '<sch:value-of select="@value" />'.  If it's new, please add it to dependency_meanings.xml.  See also guide/running.html.</sch:report>
						
		</sch:rule>
		
	</sch:pattern>
	
	
	<sch:pattern id="dependencies-in-use-descriptions">
		
		<sch:rule context="fots:dependency[not(@type = 'feature')]">
			
			<sch:assert test="doc('dependency_meanings.xml')/dependency-meanings/dependency[@type = current()/@type]/description[normalize-space(.) != '']">Missing dependency description.  Please add a description for the '<sch:value-of select="@type" />' dependency type to dependency_meanings.xml.  See also guide/running.html.</sch:assert>
			
		</sch:rule>
		
		<sch:rule context="fots:dependency[@type = 'feature']">
			
			<sch:assert test="doc('dependency_meanings.xml')/dependency-meanings/dependency[@type = 'feature']/value[@name = current()/@value]/description[normalize-space(.) != '']">Missing dependency description.  Please add a description of the '<sch:value-of select="@value" />' feature dependency to dependency_meanings.xml.  See also guide/running.html.</sch:assert>
			
		</sch:rule>
		
	</sch:pattern>

	
</sch:schema>