<?xml version="1.0" encoding="UTF-8"?>
<sch:schema 
	xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt3"
	xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
	xmlns:xs="http://www.w3.org/2001/XMLSchema">
	

	<sch:pattern id="dependency-types">
		
		<sch:rule context="dependency">
			
			<sch:assert test="@type">Missing type attribute.  Each dependency element must include a type attribute.</sch:assert>
			<sch:assert test="@type = doc('catalog-schema.xsd')/xs:schema/xs:simpleType[@name =  'dependencyEnumType']/descendant::xs:enumeration/@value">Invalid dependency type.  The value of dependency/@type must match an xs:enumeration/@value for dependencyEnumType, defined in catalog-schema.xsd.</sch:assert>

		</sch:rule>
		
	</sch:pattern>
	
	
	<sch:pattern id="descriptions">
		
		<sch:rule context="dependency">
			
			<sch:assert test="description or value/description">Missing description.  Add a description for either the dependency in general or for each of its listed values.</sch:assert>
			
		</sch:rule>
		
		<sch:rule context="value">
			
			<sch:assert test="description">Missing description.  Add a description for this value.</sch:assert>
			
		</sch:rule>
		
		<sch:rule context="description">
			
			<sch:assert test="normalize-space(.) != ''">Empty description.</sch:assert>
			
		</sch:rule>
		
	</sch:pattern>
	
</sch:schema>