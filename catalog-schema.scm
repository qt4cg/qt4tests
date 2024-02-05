<?xml version="1.0" encoding="UTF-8"?>
<scm:schema xmlns=""
             xmlns:scm="http://ns.saxonica.com/schema-component-model"
             generatedAt="2024-02-05T17:04:10.542891Z"
             xsdVersion="1.1">
   <scm:simpleType id="C0"
                    base="#anySimpleType"
                    variety="union"
                    memberTypes="C1 C2"/>
   <scm:complexType id="C3"
                     name="resourceType"
                     targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                     base="C4"
                     derivationMethod="extension"
                     abstract="false"
                     variety="element-only">
      <scm:attributeUse required="false" inheritable="false" ref="C5"/>
      <scm:attributeUse required="false" inheritable="false" ref="C6"/>
      <scm:attributeUse required="false" inheritable="false" ref="C7"/>
      <scm:attributeUse required="false" inheritable="false" ref="C8"/>
      <scm:attributeUse required="false" inheritable="false" ref="C9"/>
      <scm:modelGroupParticle minOccurs="1" maxOccurs="1">
         <scm:sequence>
            <scm:modelGroupParticle minOccurs="1" maxOccurs="1">
               <scm:sequence>
                  <scm:modelGroupParticle minOccurs="1" maxOccurs="1">
                     <scm:sequence>
                        <scm:elementParticle minOccurs="0" maxOccurs="1" ref="C10"/>
                        <scm:elementParticle minOccurs="0" maxOccurs="1" ref="C11"/>
                        <scm:elementParticle minOccurs="0" maxOccurs="unbounded" ref="C12"/>
                     </scm:sequence>
                  </scm:modelGroupParticle>
               </scm:sequence>
            </scm:modelGroupParticle>
         </scm:sequence>
      </scm:modelGroupParticle>
      <scm:finiteStateMachine initialState="0">
         <scm:state nr="0" final="true">
            <scm:edge term="C11" to="1"/>
            <scm:edge term="C10" to="2"/>
            <scm:edge term="C12" to="3"/>
         </scm:state>
         <scm:state nr="1" final="true">
            <scm:edge term="C12" to="3"/>
         </scm:state>
         <scm:state nr="2" final="true">
            <scm:edge term="C11" to="1"/>
            <scm:edge term="C12" to="3"/>
         </scm:state>
         <scm:state nr="3" final="true">
            <scm:edge term="C12" to="3"/>
         </scm:state>
      </scm:finiteStateMachine>
   </scm:complexType>
   <scm:complexType id="C13"
                     name="SequenceOfAssertionsType"
                     targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                     base="#anyType"
                     derivationMethod="restriction"
                     abstract="false"
                     variety="element-only">
      <scm:elementParticle minOccurs="1" maxOccurs="unbounded" ref="C14"/>
      <scm:finiteStateMachine initialState="0">
         <scm:state nr="0">
            <scm:edge term="C15" to="1"/>
            <scm:edge term="C16" to="1"/>
            <scm:edge term="C14" to="1"/>
            <scm:edge term="C17" to="1"/>
            <scm:edge term="C18" to="1"/>
            <scm:edge term="C19" to="1"/>
            <scm:edge term="C20" to="1"/>
            <scm:edge term="C21" to="1"/>
            <scm:edge term="C22" to="1"/>
            <scm:edge term="C23" to="1"/>
            <scm:edge term="C24" to="1"/>
            <scm:edge term="C25" to="1"/>
            <scm:edge term="C26" to="1"/>
            <scm:edge term="C27" to="1"/>
            <scm:edge term="C28" to="1"/>
            <scm:edge term="C29" to="1"/>
            <scm:edge term="C30" to="1"/>
            <scm:edge term="C31" to="1"/>
         </scm:state>
         <scm:state nr="1" final="true">
            <scm:edge term="C15" to="2"/>
            <scm:edge term="C16" to="2"/>
            <scm:edge term="C14" to="2"/>
            <scm:edge term="C17" to="2"/>
            <scm:edge term="C18" to="2"/>
            <scm:edge term="C19" to="2"/>
            <scm:edge term="C20" to="2"/>
            <scm:edge term="C21" to="2"/>
            <scm:edge term="C22" to="2"/>
            <scm:edge term="C23" to="2"/>
            <scm:edge term="C24" to="2"/>
            <scm:edge term="C25" to="2"/>
            <scm:edge term="C26" to="2"/>
            <scm:edge term="C27" to="2"/>
            <scm:edge term="C28" to="2"/>
            <scm:edge term="C29" to="2"/>
            <scm:edge term="C30" to="2"/>
            <scm:edge term="C31" to="2"/>
         </scm:state>
         <scm:state nr="2" final="true">
            <scm:edge term="C15" to="2"/>
            <scm:edge term="C16" to="2"/>
            <scm:edge term="C14" to="2"/>
            <scm:edge term="C17" to="2"/>
            <scm:edge term="C18" to="2"/>
            <scm:edge term="C19" to="2"/>
            <scm:edge term="C20" to="2"/>
            <scm:edge term="C21" to="2"/>
            <scm:edge term="C22" to="2"/>
            <scm:edge term="C23" to="2"/>
            <scm:edge term="C24" to="2"/>
            <scm:edge term="C25" to="2"/>
            <scm:edge term="C26" to="2"/>
            <scm:edge term="C27" to="2"/>
            <scm:edge term="C28" to="2"/>
            <scm:edge term="C29" to="2"/>
            <scm:edge term="C30" to="2"/>
            <scm:edge term="C31" to="2"/>
         </scm:state>
      </scm:finiteStateMachine>
   </scm:complexType>
   <scm:simpleType id="C32"
                    name="encodingType"
                    targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                    base="#string"
                    variety="atomic"
                    primitiveType="#string">
      <scm:pattern value="[A-Za-z]([A-Za-z0-9._-])*"/>
   </scm:simpleType>
   <scm:simpleType id="C33"
                    base="#string"
                    variety="atomic"
                    primitiveType="#string">
      <scm:enumeration value="*"/>
   </scm:simpleType>
   <scm:simpleType id="C2" base="#anyURI" variety="atomic" primitiveType="#anyURI">
      <scm:pattern value="http://www.w3.org/2013/collation/UCA\?.*"/>
   </scm:simpleType>
   <scm:simpleType id="C34"
                    base="#anySimpleType"
                    variety="list"
                    itemType="#NCName"/>
   <scm:simpleType id="C35"
                    base="#NCName"
                    variety="atomic"
                    primitiveType="#string">
      <scm:enumeration value="default"/>
      <scm:enumeration value="preserve"/>
   </scm:simpleType>
   <scm:simpleType id="C36"
                    base="#anySimpleType"
                    variety="union"
                    memberTypes="#language C37"/>
   <scm:simpleType id="C38"
                    name="one-char"
                    targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                    base="#string"
                    variety="atomic"
                    primitiveType="#string">
      <scm:pattern value="."/>
   </scm:simpleType>
   <scm:complexType id="C4"
                     name="baseType"
                     targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                     base="#anyType"
                     derivationMethod="restriction"
                     abstract="true"
                     variety="empty">
      <scm:attributeUse required="false" inheritable="false" ref="C9"/>
      <scm:finiteStateMachine initialState="0">
         <scm:state nr="0" final="true"/>
      </scm:finiteStateMachine>
   </scm:complexType>
   <scm:complexType id="C39"
                     name="schemaType"
                     targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                     base="C4"
                     derivationMethod="extension"
                     abstract="false"
                     variety="element-only">
      <scm:attributeUse required="false" inheritable="false" ref="C40" default="1.0">
         <scm:default lexicalForm="1.0">
            <scm:item type="#decimal" value="1"/>
         </scm:default>
      </scm:attributeUse>
      <scm:attributeUse required="false" inheritable="false" ref="C6"/>
      <scm:attributeUse required="false" inheritable="false" ref="C5"/>
      <scm:attributeUse required="false" inheritable="false" ref="C41"/>
      <scm:attributeUse required="false" inheritable="false" ref="C9"/>
      <scm:modelGroupParticle minOccurs="1" maxOccurs="1">
         <scm:sequence>
            <scm:modelGroupParticle minOccurs="1" maxOccurs="1">
               <scm:sequence>
                  <scm:elementParticle minOccurs="0" maxOccurs="1" ref="C10"/>
                  <scm:elementParticle minOccurs="0" maxOccurs="1" ref="C11"/>
                  <scm:elementParticle minOccurs="0" maxOccurs="unbounded" ref="C12"/>
               </scm:sequence>
            </scm:modelGroupParticle>
         </scm:sequence>
      </scm:modelGroupParticle>
      <scm:finiteStateMachine initialState="0">
         <scm:state nr="0" final="true">
            <scm:edge term="C11" to="1"/>
            <scm:edge term="C10" to="2"/>
            <scm:edge term="C12" to="3"/>
         </scm:state>
         <scm:state nr="1" final="true">
            <scm:edge term="C12" to="3"/>
         </scm:state>
         <scm:state nr="2" final="true">
            <scm:edge term="C11" to="1"/>
            <scm:edge term="C12" to="3"/>
         </scm:state>
         <scm:state nr="3" final="true">
            <scm:edge term="C12" to="3"/>
         </scm:state>
      </scm:finiteStateMachine>
   </scm:complexType>
   <scm:complexType id="C42"
                     name="sourceType"
                     targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                     base="C4"
                     derivationMethod="extension"
                     abstract="false"
                     variety="element-only">
      <scm:attributeUse required="false" inheritable="false" ref="C43"/>
      <scm:attributeUse required="false" inheritable="false" ref="C44"/>
      <scm:attributeUse required="false" inheritable="false" ref="C41"/>
      <scm:attributeUse required="false" inheritable="false" ref="C5"/>
      <scm:attributeUse required="false" inheritable="false" ref="C6"/>
      <scm:attributeUse required="false" inheritable="false" ref="C45"/>
      <scm:attributeUse required="false" inheritable="false" ref="C9"/>
      <scm:modelGroupParticle minOccurs="1" maxOccurs="1">
         <scm:sequence>
            <scm:modelGroupParticle minOccurs="1" maxOccurs="1">
               <scm:sequence>
                  <scm:elementParticle minOccurs="0" maxOccurs="1" ref="C10"/>
                  <scm:elementParticle minOccurs="0" maxOccurs="1" ref="C11"/>
                  <scm:elementParticle minOccurs="0" maxOccurs="unbounded" ref="C12"/>
               </scm:sequence>
            </scm:modelGroupParticle>
         </scm:sequence>
      </scm:modelGroupParticle>
      <scm:finiteStateMachine initialState="0">
         <scm:state nr="0" final="true">
            <scm:edge term="C10" to="1"/>
            <scm:edge term="C12" to="2"/>
            <scm:edge term="C11" to="3"/>
         </scm:state>
         <scm:state nr="1" final="true">
            <scm:edge term="C12" to="2"/>
            <scm:edge term="C11" to="3"/>
         </scm:state>
         <scm:state nr="2" final="true">
            <scm:edge term="C12" to="2"/>
         </scm:state>
         <scm:state nr="3" final="true">
            <scm:edge term="C12" to="2"/>
         </scm:state>
      </scm:finiteStateMachine>
   </scm:complexType>
   <scm:simpleType id="C37"
                    base="#string"
                    variety="atomic"
                    primitiveType="#string">
      <scm:enumeration value=""/>
   </scm:simpleType>
   <scm:simpleType id="C46"
                    name="dependencyEnumType"
                    targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                    base="#normalizedString"
                    variety="atomic"
                    primitiveType="#string">
      <scm:enumeration value="language"/>
      <scm:enumeration value="put"/>
      <scm:enumeration value="xml-version"/>
      <scm:enumeration value="spec"/>
      <scm:enumeration value="unicode-normalization-form"/>
      <scm:enumeration value="format-integer-sequence"/>
      <scm:enumeration value="unicode-version"/>
      <scm:enumeration value="calendar"/>
      <scm:enumeration value="collection-stability"/>
      <scm:enumeration value="feature"/>
      <scm:enumeration value="schemaAware"/>
      <scm:enumeration value="revalidation"/>
      <scm:enumeration value="default-language"/>
      <scm:enumeration value="limits"/>
      <scm:enumeration value="directory-as-collection-uri"/>
      <scm:enumeration value="xsd-version"/>
   </scm:simpleType>
   <scm:simpleType id="C47" base="#anySimpleType" variety="list" itemType="#token"/>
   <scm:simpleType id="C48"
                    name="validationEnumType"
                    targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                    base="#normalizedString"
                    variety="atomic"
                    primitiveType="#string">
      <scm:enumeration value="skip"/>
      <scm:enumeration value="lax"/>
      <scm:enumeration value="strict"/>
   </scm:simpleType>
   <scm:simpleType id="C49"
                    base="#string"
                    variety="atomic"
                    primitiveType="#string">
      <scm:pattern value="[0-9A-Z](\.*[0-9]+)*"/>
   </scm:simpleType>
   <scm:simpleType id="C50"
                    base="#anySimpleType"
                    variety="union"
                    memberTypes="#NCName C51 C33"/>
   <scm:simpleType id="C52"
                    base="#anySimpleType"
                    variety="list"
                    itemType="#NCName"/>
   <scm:simpleType id="C51"
                    name="EQName"
                    targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                    base="#string"
                    variety="atomic"
                    primitiveType="#string">
      <scm:pattern value="Q\{.*\}\i\c*"/>
   </scm:simpleType>
   <scm:simpleType id="C1" base="#anyURI" variety="atomic" primitiveType="#anyURI">
      <scm:enumeration value="http://www.w3.org/2005/xpath-functions/collation/codepoint"/>
      <scm:enumeration value="http://www.w3.org/2010/09/qt-fots-catalog/collation/caseblind"/>
      <scm:enumeration value="http://www.w3.org/2005/xpath-functions/collation/html-ascii-case-insensitive"/>
   </scm:simpleType>
   <scm:element id="C53"
                 name="namespace"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C54"
                 global="true"
                 nillable="false"
                 abstract="false"/>
   <scm:element id="C55"
                 name="environment"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C56"
                 global="true"
                 nillable="false"
                 abstract="false"/>
   <scm:element id="C57"
                 name="test-case"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C58"
                 global="true"
                 nillable="false"
                 abstract="false"/>
   <scm:element id="C23"
                 name="assert-false"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="#anyType"
                 global="true"
                 nillable="false"
                 abstract="false">
      <scm:substitutionGroupAffiliation ref="C14"/>
   </scm:element>
   <scm:element id="C14"
                 name="abstractAssertion"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="#anyType"
                 global="true"
                 nillable="false"
                 abstract="true"/>
   <scm:element id="C26"
                 name="assert-string-value"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C59"
                 global="true"
                 nillable="false"
                 abstract="false">
      <scm:substitutionGroupAffiliation ref="C14"/>
   </scm:element>
   <scm:element id="C17"
                 name="assert-deep-eq"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C60"
                 global="true"
                 nillable="false"
                 abstract="false">
      <scm:substitutionGroupAffiliation ref="C14"/>
   </scm:element>
   <scm:element id="C16"
                 name="assert-count"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C61"
                 global="true"
                 nillable="false"
                 abstract="false">
      <scm:substitutionGroupAffiliation ref="C14"/>
   </scm:element>
   <scm:element id="C62"
                 name="result"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C63"
                 global="true"
                 nillable="false"
                 abstract="false"/>
   <scm:element id="C29"
                 name="not"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C64"
                 global="true"
                 nillable="false"
                 abstract="false">
      <scm:substitutionGroupAffiliation ref="C14"/>
   </scm:element>
   <scm:element id="C65"
                 name="param"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C66"
                 global="true"
                 nillable="false"
                 abstract="false"/>
   <scm:element id="C31"
                 name="assert"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C67"
                 global="true"
                 nillable="false"
                 abstract="false">
      <scm:substitutionGroupAffiliation ref="C14"/>
   </scm:element>
   <scm:element id="C21"
                 name="assert-true"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="#anyType"
                 global="true"
                 nillable="false"
                 abstract="false">
      <scm:substitutionGroupAffiliation ref="C14"/>
   </scm:element>
   <scm:element id="C68"
                 name="link"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C69"
                 global="true"
                 nillable="false"
                 abstract="false"/>
   <scm:element id="C10"
                 name="description"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C70"
                 global="true"
                 nillable="false"
                 abstract="false"/>
   <scm:element id="C30"
                 name="error"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C71"
                 global="true"
                 nillable="false"
                 abstract="false">
      <scm:substitutionGroupAffiliation ref="C14"/>
   </scm:element>
   <scm:element id="C72"
                 name="schema"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C39"
                 global="true"
                 nillable="false"
                 abstract="false"/>
   <scm:element id="C15"
                 name="assert-eq"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C73"
                 global="true"
                 nillable="false"
                 abstract="false">
      <scm:substitutionGroupAffiliation ref="C14"/>
   </scm:element>
   <scm:element id="C74"
                 name="context-item"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C75"
                 global="true"
                 nillable="false"
                 abstract="false"/>
   <scm:element id="C76"
                 name="test-set"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C77"
                 global="true"
                 nillable="false"
                 abstract="false"/>
   <scm:element id="C20"
                 name="assert-empty"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="#anyType"
                 global="true"
                 nillable="false"
                 abstract="false">
      <scm:substitutionGroupAffiliation ref="C14"/>
   </scm:element>
   <scm:element id="C28"
                 name="all-of"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C13"
                 global="true"
                 nillable="false"
                 abstract="false">
      <scm:substitutionGroupAffiliation ref="C14"/>
   </scm:element>
   <scm:element id="C78"
                 name="collection"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C79"
                 global="true"
                 nillable="false"
                 abstract="false"/>
   <scm:element id="C80"
                 name="decimal-format"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C81"
                 global="true"
                 nillable="false"
                 abstract="false"/>
   <scm:element id="C82"
                 name="static-base-uri"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C83"
                 global="true"
                 nillable="false"
                 abstract="false"/>
   <scm:element id="C84"
                 name="function-library"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C85"
                 global="true"
                 nillable="false"
                 abstract="false"/>
   <scm:element id="C86"
                 name="test"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C87"
                 global="true"
                 nillable="false"
                 abstract="false"/>
   <scm:element id="C88"
                 name="resource"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C3"
                 global="true"
                 nillable="false"
                 abstract="false"/>
   <scm:element id="C89"
                 name="dependency"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C90"
                 global="true"
                 nillable="false"
                 abstract="false"/>
   <scm:element id="C11"
                 name="created"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C91"
                 global="true"
                 nillable="false"
                 abstract="false"/>
   <scm:element id="C92"
                 name="query"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="#anyType"
                 global="true"
                 nillable="false"
                 abstract="false"/>
   <scm:element id="C93"
                 name="module"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C94"
                 global="true"
                 nillable="false"
                 abstract="false"/>
   <scm:element id="C12"
                 name="modified"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C95"
                 global="true"
                 nillable="false"
                 abstract="false"/>
   <scm:element id="C96"
                 name="collation"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C97"
                 global="true"
                 nillable="false"
                 abstract="false"/>
   <scm:element id="C18"
                 name="assert-permutation"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C98"
                 global="true"
                 nillable="false"
                 abstract="false">
      <scm:substitutionGroupAffiliation ref="C14"/>
   </scm:element>
   <scm:element id="C19"
                 name="assert-xml"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C99"
                 global="true"
                 nillable="false"
                 abstract="false">
      <scm:substitutionGroupAffiliation ref="C14"/>
   </scm:element>
   <scm:element id="C27"
                 name="any-of"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C13"
                 global="true"
                 nillable="false"
                 abstract="false">
      <scm:substitutionGroupAffiliation ref="C14"/>
   </scm:element>
   <scm:element id="C22"
                 name="serialization-matches"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C100"
                 global="true"
                 nillable="false"
                 abstract="false">
      <scm:substitutionGroupAffiliation ref="C14"/>
   </scm:element>
   <scm:element id="C101"
                 name="source"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C42"
                 global="true"
                 nillable="false"
                 abstract="false"/>
   <scm:element id="C24"
                 name="assert-serialization-error"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C102"
                 global="true"
                 nillable="false"
                 abstract="false">
      <scm:substitutionGroupAffiliation ref="C14"/>
   </scm:element>
   <scm:element id="C25"
                 name="assert-type"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C103"
                 global="true"
                 nillable="false"
                 abstract="false">
      <scm:substitutionGroupAffiliation ref="C14"/>
   </scm:element>
   <scm:element id="C104"
                 name="catalog"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C105"
                 global="true"
                 nillable="false"
                 abstract="false"/>
   <scm:attribute id="C9"
                   name="id"
                   targetNamespace="http://www.w3.org/XML/1998/namespace"
                   type="#ID"
                   global="true"
                   inheritable="false"/>
   <scm:attribute id="C106"
                   name="lang"
                   targetNamespace="http://www.w3.org/XML/1998/namespace"
                   type="C36"
                   global="true"
                   inheritable="false"/>
   <scm:attribute id="C107"
                   name="space"
                   targetNamespace="http://www.w3.org/XML/1998/namespace"
                   type="C35"
                   global="true"
                   inheritable="false"/>
   <scm:attribute id="C108"
                   name="base"
                   targetNamespace="http://www.w3.org/XML/1998/namespace"
                   type="#anyURI"
                   global="true"
                   inheritable="false"/>
   <scm:attributeGroup id="C109"
                        name="refAttr"
                        targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog">
      <scm:attributeUse required="false" inheritable="false" ref="C110"/>
   </scm:attributeGroup>
   <scm:attributeGroup id="C111"
                        name="covers30Attr"
                        targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog">
      <scm:attributeUse required="false" inheritable="false" ref="C112"/>
      <scm:attributeUse required="false" inheritable="false" ref="C113"/>
   </scm:attributeGroup>
   <scm:attributeGroup id="C114"
                        name="nameAttr"
                        targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog">
      <scm:attributeUse required="false" inheritable="false" ref="C115"/>
   </scm:attributeGroup>
   <scm:attributeGroup id="C116"
                        name="valueAttr"
                        targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog">
      <scm:attributeUse required="false" inheritable="false" ref="C117"/>
   </scm:attributeGroup>
   <scm:attributeGroup id="C118"
                        name="roleAttr"
                        targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog">
      <scm:attributeUse required="false" inheritable="false" ref="C41"/>
   </scm:attributeGroup>
   <scm:attributeGroup id="C119"
                        name="encodingAttr"
                        targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog">
      <scm:attributeUse required="false" inheritable="false" ref="C8"/>
   </scm:attributeGroup>
   <scm:attributeGroup id="C120"
                        name="uriAttr"
                        targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog">
      <scm:attributeUse required="false" inheritable="false" ref="C6"/>
   </scm:attributeGroup>
   <scm:attributeGroup id="C121"
                        name="specialAttrs"
                        targetNamespace="http://www.w3.org/XML/1998/namespace">
      <scm:attributeUse required="false" inheritable="false" ref="C108"/>
      <scm:attributeUse required="false" inheritable="false" ref="C106"/>
      <scm:attributeUse required="false" inheritable="false" ref="C107"/>
      <scm:attributeUse required="false" inheritable="false" ref="C9"/>
   </scm:attributeGroup>
   <scm:attributeGroup id="C122"
                        name="byAttr"
                        targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog">
      <scm:attributeUse required="false" inheritable="false" ref="C123"/>
   </scm:attributeGroup>
   <scm:attributeGroup id="C124"
                        name="typeAttr"
                        targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog">
      <scm:attributeUse required="false" inheritable="false" ref="C125"/>
   </scm:attributeGroup>
   <scm:attributeGroup id="C126"
                        name="fileAttr"
                        targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog">
      <scm:attributeUse required="false" inheritable="false" ref="C5"/>
   </scm:attributeGroup>
   <scm:attributeGroup id="C127"
                        name="validationAttr"
                        targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog">
      <scm:attributeUse required="false" inheritable="false" ref="C45"/>
   </scm:attributeGroup>
   <scm:attributeGroup id="C128"
                        name="media-typeAttr"
                        targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog">
      <scm:attributeUse required="false" inheritable="false" ref="C7"/>
   </scm:attributeGroup>
   <scm:attributeGroup id="C129"
                        name="coversAttr"
                        targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog">
      <scm:attributeUse required="false" inheritable="false" ref="C130"/>
   </scm:attributeGroup>
   <scm:attributeGroup id="C131"
                        name="documentAttr"
                        targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog">
      <scm:attributeUse required="false" inheritable="false" ref="C132"/>
   </scm:attributeGroup>
   <scm:attributeGroup id="C133"
                        name="creatorAttr"
                        targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog">
      <scm:attributeUse required="false" inheritable="false" ref="C134"/>
   </scm:attributeGroup>
   <scm:attributeGroup id="C135"
                        name="changeAttr"
                        targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog">
      <scm:attributeUse required="false" inheritable="false" ref="C136"/>
   </scm:attributeGroup>
   <scm:attributeGroup id="C137"
                        name="codeAttr"
                        targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog">
      <scm:attributeUse required="false" inheritable="false" ref="C138"/>
   </scm:attributeGroup>
   <scm:attributeGroup id="C139"
                        name="onAttr"
                        targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog">
      <scm:attributeUse required="false" inheritable="false" ref="C140"/>
   </scm:attributeGroup>
   <scm:attribute id="C5"
                   name="file"
                   type="#anyURI"
                   global="false"
                   inheritable="false"/>
   <scm:attribute id="C6"
                   name="uri"
                   type="#anyURI"
                   global="false"
                   inheritable="false"/>
   <scm:attribute id="C7"
                   name="media-type"
                   type="#string"
                   global="false"
                   inheritable="false"/>
   <scm:attribute id="C8"
                   name="encoding"
                   type="C32"
                   global="false"
                   inheritable="false"/>
   <scm:attribute id="C40"
                   name="xsd-version"
                   type="#decimal"
                   global="false"
                   inheritable="false"
                   containingComplexType="C39"/>
   <scm:attribute id="C41"
                   name="role"
                   type="#string"
                   global="false"
                   inheritable="false"/>
   <scm:attribute id="C43"
                   name="mutable"
                   type="#boolean"
                   global="false"
                   inheritable="false"
                   containingComplexType="C42"/>
   <scm:attribute id="C44"
                   name="declared"
                   type="#boolean"
                   global="false"
                   inheritable="false"
                   containingComplexType="C42"/>
   <scm:attribute id="C45"
                   name="validation"
                   type="C48"
                   global="false"
                   inheritable="false"/>
   <scm:complexType id="C54"
                     base="#anyType"
                     derivationMethod="restriction"
                     abstract="false"
                     variety="empty">
      <scm:attributeUse required="false" inheritable="false" ref="C141"/>
      <scm:attributeUse required="false" inheritable="false" ref="C142"/>
      <scm:finiteStateMachine initialState="0">
         <scm:state nr="0" final="true"/>
      </scm:finiteStateMachine>
   </scm:complexType>
   <scm:complexType id="C56"
                     base="C4"
                     derivationMethod="extension"
                     abstract="false"
                     variety="element-only">
      <scm:attributeUse required="false" inheritable="false" ref="C115"/>
      <scm:attributeUse required="false" inheritable="false" ref="C110"/>
      <scm:attributeUse required="false" inheritable="false" ref="C9"/>
      <scm:modelGroupParticle minOccurs="0" maxOccurs="unbounded">
         <scm:choice>
            <scm:elementParticle minOccurs="1" maxOccurs="1" ref="C72"/>
            <scm:elementParticle minOccurs="1" maxOccurs="1" ref="C101"/>
            <scm:elementParticle minOccurs="1" maxOccurs="1" ref="C88"/>
            <scm:elementParticle minOccurs="1" maxOccurs="1" ref="C65"/>
            <scm:elementParticle minOccurs="1" maxOccurs="1" ref="C74"/>
            <scm:elementParticle minOccurs="1" maxOccurs="1" ref="C80"/>
            <scm:elementParticle minOccurs="1" maxOccurs="1" ref="C53"/>
            <scm:elementParticle minOccurs="1" maxOccurs="1" ref="C84"/>
            <scm:elementParticle minOccurs="1" maxOccurs="1" ref="C78"/>
            <scm:elementParticle minOccurs="1" maxOccurs="1" ref="C82"/>
            <scm:elementParticle minOccurs="1" maxOccurs="1" ref="C96"/>
         </scm:choice>
      </scm:modelGroupParticle>
      <scm:finiteStateMachine initialState="0">
         <scm:state nr="0" final="true">
            <scm:edge term="C96" to="1"/>
            <scm:edge term="C88" to="1"/>
            <scm:edge term="C72" to="1"/>
            <scm:edge term="C84" to="1"/>
            <scm:edge term="C80" to="1"/>
            <scm:edge term="C82" to="1"/>
            <scm:edge term="C65" to="1"/>
            <scm:edge term="C53" to="1"/>
            <scm:edge term="C74" to="1"/>
            <scm:edge term="C78" to="1"/>
            <scm:edge term="C101" to="1"/>
         </scm:state>
         <scm:state nr="1" final="true">
            <scm:edge term="C96" to="1"/>
            <scm:edge term="C88" to="1"/>
            <scm:edge term="C72" to="1"/>
            <scm:edge term="C84" to="1"/>
            <scm:edge term="C80" to="1"/>
            <scm:edge term="C82" to="1"/>
            <scm:edge term="C65" to="1"/>
            <scm:edge term="C53" to="1"/>
            <scm:edge term="C74" to="1"/>
            <scm:edge term="C78" to="1"/>
            <scm:edge term="C101" to="1"/>
         </scm:state>
      </scm:finiteStateMachine>
   </scm:complexType>
   <scm:complexType id="C58"
                     base="#anyType"
                     derivationMethod="restriction"
                     abstract="false"
                     variety="element-only">
      <scm:attributeUse required="false" inheritable="false" ref="C115"/>
      <scm:attributeUse required="false" inheritable="false" ref="C130"/>
      <scm:attributeUse required="false" inheritable="false" ref="C112"/>
      <scm:attributeUse required="false" inheritable="false" ref="C113"/>
      <scm:modelGroupParticle minOccurs="1" maxOccurs="1">
         <scm:sequence>
            <scm:elementParticle minOccurs="1" maxOccurs="1" ref="C10"/>
            <scm:elementParticle minOccurs="1" maxOccurs="1" ref="C11"/>
            <scm:elementParticle minOccurs="0" maxOccurs="unbounded" ref="C12"/>
            <scm:modelGroupParticle minOccurs="0" maxOccurs="unbounded">
               <scm:choice>
                  <scm:elementParticle minOccurs="1" maxOccurs="1" ref="C55"/>
                  <scm:elementParticle minOccurs="1" maxOccurs="1" ref="C93"/>
                  <scm:elementParticle minOccurs="1" maxOccurs="1" ref="C89"/>
               </scm:choice>
            </scm:modelGroupParticle>
            <scm:elementParticle minOccurs="1" maxOccurs="unbounded" ref="C86"/>
            <scm:elementParticle minOccurs="1" maxOccurs="1" ref="C62"/>
         </scm:sequence>
      </scm:modelGroupParticle>
      <scm:finiteStateMachine initialState="0">
         <scm:state nr="0">
            <scm:edge term="C10" to="1"/>
         </scm:state>
         <scm:state nr="1">
            <scm:edge term="C11" to="2"/>
         </scm:state>
         <scm:state nr="2">
            <scm:edge term="C86" to="3"/>
            <scm:edge term="C93" to="4"/>
            <scm:edge term="C89" to="4"/>
            <scm:edge term="C12" to="5"/>
            <scm:edge term="C55" to="4"/>
         </scm:state>
         <scm:state nr="3">
            <scm:edge term="C86" to="6"/>
            <scm:edge term="C62" to="7"/>
         </scm:state>
         <scm:state nr="4">
            <scm:edge term="C86" to="3"/>
            <scm:edge term="C93" to="4"/>
            <scm:edge term="C89" to="4"/>
            <scm:edge term="C55" to="4"/>
         </scm:state>
         <scm:state nr="5">
            <scm:edge term="C86" to="3"/>
            <scm:edge term="C93" to="4"/>
            <scm:edge term="C89" to="4"/>
            <scm:edge term="C12" to="5"/>
            <scm:edge term="C55" to="4"/>
         </scm:state>
         <scm:state nr="6">
            <scm:edge term="C86" to="6"/>
            <scm:edge term="C62" to="7"/>
         </scm:state>
         <scm:state nr="7" final="true"/>
      </scm:finiteStateMachine>
   </scm:complexType>
   <scm:complexType id="C59"
                     base="#string"
                     derivationMethod="extension"
                     abstract="false"
                     variety="simple"
                     simpleType="#string">
      <scm:attributeUse required="false" inheritable="false" ref="C143" default="false">
         <scm:default lexicalForm="false">
            <scm:item type="#boolean" value="false"/>
         </scm:default>
      </scm:attributeUse>
   </scm:complexType>
   <scm:complexType id="C60"
                     base="#string"
                     derivationMethod="extension"
                     abstract="false"
                     variety="simple"
                     simpleType="#string"/>
   <scm:complexType id="C61"
                     base="#integer"
                     derivationMethod="extension"
                     abstract="false"
                     variety="simple"
                     simpleType="#integer"/>
   <scm:complexType id="C63"
                     base="#anyType"
                     derivationMethod="restriction"
                     abstract="false"
                     variety="element-only">
      <scm:elementParticle minOccurs="1" maxOccurs="1" ref="C14"/>
      <scm:finiteStateMachine initialState="0">
         <scm:state nr="0">
            <scm:edge term="C27" to="1"/>
            <scm:edge term="C28" to="1"/>
            <scm:edge term="C29" to="1"/>
            <scm:edge term="C30" to="1"/>
            <scm:edge term="C31" to="1"/>
            <scm:edge term="C25" to="1"/>
            <scm:edge term="C26" to="1"/>
            <scm:edge term="C19" to="1"/>
            <scm:edge term="C20" to="1"/>
            <scm:edge term="C21" to="1"/>
            <scm:edge term="C22" to="1"/>
            <scm:edge term="C23" to="1"/>
            <scm:edge term="C24" to="1"/>
            <scm:edge term="C15" to="1"/>
            <scm:edge term="C16" to="1"/>
            <scm:edge term="C14" to="1"/>
            <scm:edge term="C17" to="1"/>
            <scm:edge term="C18" to="1"/>
         </scm:state>
         <scm:state nr="1" final="true"/>
      </scm:finiteStateMachine>
   </scm:complexType>
   <scm:complexType id="C64"
                     base="#anyType"
                     derivationMethod="restriction"
                     abstract="false"
                     variety="element-only">
      <scm:elementParticle minOccurs="1" maxOccurs="1" ref="C14"/>
      <scm:finiteStateMachine initialState="0">
         <scm:state nr="0">
            <scm:edge term="C23" to="1"/>
            <scm:edge term="C24" to="1"/>
            <scm:edge term="C20" to="1"/>
            <scm:edge term="C19" to="1"/>
            <scm:edge term="C22" to="1"/>
            <scm:edge term="C21" to="1"/>
            <scm:edge term="C14" to="1"/>
            <scm:edge term="C17" to="1"/>
            <scm:edge term="C18" to="1"/>
            <scm:edge term="C15" to="1"/>
            <scm:edge term="C16" to="1"/>
            <scm:edge term="C31" to="1"/>
            <scm:edge term="C27" to="1"/>
            <scm:edge term="C29" to="1"/>
            <scm:edge term="C30" to="1"/>
            <scm:edge term="C28" to="1"/>
            <scm:edge term="C26" to="1"/>
            <scm:edge term="C25" to="1"/>
         </scm:state>
         <scm:state nr="1" final="true"/>
      </scm:finiteStateMachine>
   </scm:complexType>
   <scm:complexType id="C66"
                     base="#anyType"
                     derivationMethod="restriction"
                     abstract="false"
                     variety="empty">
      <scm:attributeUse required="true" inheritable="false" ref="C144"/>
      <scm:attributeUse required="false" inheritable="false" ref="C145"/>
      <scm:attributeUse required="false" inheritable="false" ref="C146"/>
      <scm:attributeUse required="false" inheritable="false" ref="C147"/>
      <scm:attributeUse required="false" inheritable="false" ref="C148" default="false">
         <scm:default lexicalForm="false">
            <scm:item type="#boolean" value="false"/>
         </scm:default>
      </scm:attributeUse>
      <scm:finiteStateMachine initialState="0">
         <scm:state nr="0" final="true"/>
      </scm:finiteStateMachine>
   </scm:complexType>
   <scm:complexType id="C67"
                     base="#string"
                     derivationMethod="extension"
                     abstract="false"
                     variety="simple"
                     simpleType="#string"/>
   <scm:complexType id="C69"
                     base="#anyType"
                     derivationMethod="restriction"
                     abstract="false"
                     variety="empty">
      <scm:attributeUse required="false" inheritable="false" ref="C149"/>
      <scm:attributeUse required="false" inheritable="false" ref="C150"/>
      <scm:attributeUse required="false" inheritable="false" ref="C125"/>
      <scm:attributeUse required="false" inheritable="false" ref="C132"/>
      <scm:finiteStateMachine initialState="0">
         <scm:state nr="0" final="true"/>
      </scm:finiteStateMachine>
   </scm:complexType>
   <scm:complexType id="C70"
                     base="#string"
                     derivationMethod="extension"
                     abstract="false"
                     variety="simple"
                     simpleType="#string"/>
   <scm:complexType id="C71"
                     base="#anyType"
                     derivationMethod="restriction"
                     abstract="false"
                     variety="empty">
      <scm:attributeUse required="false" inheritable="false" ref="C138"/>
      <scm:finiteStateMachine initialState="0">
         <scm:state nr="0" final="true"/>
      </scm:finiteStateMachine>
   </scm:complexType>
   <scm:complexType id="C73"
                     base="#string"
                     derivationMethod="extension"
                     abstract="false"
                     variety="simple"
                     simpleType="#string"/>
   <scm:complexType id="C75"
                     base="#anyType"
                     derivationMethod="restriction"
                     abstract="false"
                     variety="empty">
      <scm:attributeUse required="false" inheritable="false" ref="C151"/>
      <scm:finiteStateMachine initialState="0">
         <scm:state nr="0" final="true"/>
      </scm:finiteStateMachine>
   </scm:complexType>
   <scm:complexType id="C77"
                     base="#anyType"
                     derivationMethod="restriction"
                     abstract="false"
                     variety="element-only">
      <scm:attributeUse required="false" inheritable="false" ref="C115"/>
      <scm:attributeUse required="false" inheritable="false" ref="C130"/>
      <scm:attributeUse required="false" inheritable="false" ref="C112"/>
      <scm:attributeUse required="false" inheritable="false" ref="C113"/>
      <scm:modelGroupParticle minOccurs="1" maxOccurs="1">
         <scm:sequence>
            <scm:modelGroupParticle minOccurs="1" maxOccurs="unbounded">
               <scm:choice>
                  <scm:elementParticle minOccurs="1" maxOccurs="1" ref="C10"/>
                  <scm:elementParticle minOccurs="1" maxOccurs="1" ref="C68"/>
                  <scm:elementParticle minOccurs="1" maxOccurs="1" ref="C55"/>
                  <scm:elementParticle minOccurs="1" maxOccurs="1" ref="C89"/>
               </scm:choice>
            </scm:modelGroupParticle>
            <scm:elementParticle minOccurs="1" maxOccurs="unbounded" ref="C57"/>
         </scm:sequence>
      </scm:modelGroupParticle>
      <scm:finiteStateMachine initialState="0">
         <scm:state nr="0">
            <scm:edge term="C10" to="1"/>
            <scm:edge term="C68" to="1"/>
            <scm:edge term="C89" to="1"/>
            <scm:edge term="C55" to="1"/>
         </scm:state>
         <scm:state nr="1">
            <scm:edge term="C10" to="2"/>
            <scm:edge term="C68" to="2"/>
            <scm:edge term="C89" to="2"/>
            <scm:edge term="C57" to="3"/>
            <scm:edge term="C55" to="2"/>
         </scm:state>
         <scm:state nr="2">
            <scm:edge term="C10" to="2"/>
            <scm:edge term="C68" to="2"/>
            <scm:edge term="C89" to="2"/>
            <scm:edge term="C57" to="3"/>
            <scm:edge term="C55" to="2"/>
         </scm:state>
         <scm:state nr="3" final="true">
            <scm:edge term="C57" to="4"/>
         </scm:state>
         <scm:state nr="4" final="true">
            <scm:edge term="C57" to="4"/>
         </scm:state>
      </scm:finiteStateMachine>
   </scm:complexType>
   <scm:complexType id="C79"
                     base="#anyType"
                     derivationMethod="restriction"
                     abstract="false"
                     variety="element-only">
      <scm:attributeUse required="false" inheritable="false" ref="C6"/>
      <scm:modelGroupParticle minOccurs="1" maxOccurs="1">
         <scm:sequence>
            <scm:elementParticle minOccurs="0" maxOccurs="unbounded" ref="C101"/>
            <scm:elementParticle minOccurs="0" maxOccurs="unbounded" ref="C88"/>
            <scm:elementParticle minOccurs="0" maxOccurs="unbounded" ref="C92"/>
         </scm:sequence>
      </scm:modelGroupParticle>
      <scm:finiteStateMachine initialState="0">
         <scm:state nr="0" final="true">
            <scm:edge term="C92" to="1"/>
            <scm:edge term="C101" to="2"/>
            <scm:edge term="C88" to="3"/>
         </scm:state>
         <scm:state nr="1" final="true">
            <scm:edge term="C92" to="1"/>
         </scm:state>
         <scm:state nr="2" final="true">
            <scm:edge term="C92" to="1"/>
            <scm:edge term="C101" to="2"/>
            <scm:edge term="C88" to="3"/>
         </scm:state>
         <scm:state nr="3" final="true">
            <scm:edge term="C92" to="1"/>
            <scm:edge term="C88" to="3"/>
         </scm:state>
      </scm:finiteStateMachine>
   </scm:complexType>
   <scm:complexType id="C81"
                     base="#anyType"
                     derivationMethod="restriction"
                     abstract="false"
                     variety="empty">
      <scm:attributeUse required="false" inheritable="false" ref="C152"/>
      <scm:attributeUse required="false" inheritable="false" ref="C153"/>
      <scm:attributeUse required="false" inheritable="false" ref="C154"/>
      <scm:attributeUse required="false" inheritable="false" ref="C155"/>
      <scm:attributeUse required="false" inheritable="false" ref="C156"/>
      <scm:attributeUse required="false" inheritable="false" ref="C157"/>
      <scm:attributeUse required="false" inheritable="false" ref="C158"/>
      <scm:attributeUse required="false" inheritable="false" ref="C159"/>
      <scm:attributeUse required="false" inheritable="false" ref="C160"/>
      <scm:attributeUse required="false" inheritable="false" ref="C161"/>
      <scm:attributeUse required="false" inheritable="false" ref="C162"/>
      <scm:attributeUse required="false" inheritable="false" ref="C163"/>
      <scm:finiteStateMachine initialState="0">
         <scm:state nr="0" final="true"/>
      </scm:finiteStateMachine>
   </scm:complexType>
   <scm:complexType id="C83"
                     base="#anyType"
                     derivationMethod="restriction"
                     abstract="false"
                     variety="empty">
      <scm:attributeUse required="false" inheritable="false" ref="C6"/>
      <scm:finiteStateMachine initialState="0">
         <scm:state nr="0" final="true"/>
      </scm:finiteStateMachine>
   </scm:complexType>
   <scm:complexType id="C85"
                     base="#anyType"
                     derivationMethod="restriction"
                     abstract="false"
                     variety="empty">
      <scm:attributeUse required="false" inheritable="false" ref="C164"/>
      <scm:attributeUse required="false" inheritable="false" ref="C165"/>
      <scm:attributeUse required="false" inheritable="false" ref="C115"/>
      <scm:finiteStateMachine initialState="0">
         <scm:state nr="0" final="true"/>
      </scm:finiteStateMachine>
   </scm:complexType>
   <scm:complexType id="C87"
                     base="#string"
                     derivationMethod="extension"
                     abstract="false"
                     variety="simple"
                     simpleType="#string">
      <scm:attributeUse required="false" inheritable="false" ref="C166"/>
      <scm:attributeUse required="false" inheritable="false" ref="C167"/>
   </scm:complexType>
   <scm:complexType id="C90"
                     base="#anyType"
                     derivationMethod="restriction"
                     abstract="false"
                     variety="empty">
      <scm:attributeUse required="false" inheritable="false" ref="C168" default="true">
         <scm:default lexicalForm="true">
            <scm:item type="#boolean" value="true"/>
         </scm:default>
      </scm:attributeUse>
      <scm:attributeUse required="false" inheritable="false" ref="C125"/>
      <scm:attributeUse required="false" inheritable="false" ref="C117"/>
      <scm:finiteStateMachine initialState="0">
         <scm:state nr="0" final="true"/>
      </scm:finiteStateMachine>
   </scm:complexType>
   <scm:complexType id="C91"
                     base="#anyType"
                     derivationMethod="restriction"
                     abstract="false"
                     variety="empty">
      <scm:attributeUse required="false" inheritable="false" ref="C123"/>
      <scm:attributeUse required="false" inheritable="false" ref="C140"/>
      <scm:finiteStateMachine initialState="0">
         <scm:state nr="0" final="true"/>
      </scm:finiteStateMachine>
   </scm:complexType>
   <scm:complexType id="C94"
                     base="#anyType"
                     derivationMethod="restriction"
                     abstract="false"
                     variety="empty">
      <scm:attributeUse required="false" inheritable="false" ref="C169"/>
      <scm:attributeUse required="false" inheritable="false" ref="C170"/>
      <scm:attributeUse required="false" inheritable="false" ref="C171"/>
      <scm:finiteStateMachine initialState="0">
         <scm:state nr="0" final="true"/>
      </scm:finiteStateMachine>
   </scm:complexType>
   <scm:complexType id="C95"
                     base="#anyType"
                     derivationMethod="restriction"
                     abstract="false"
                     variety="empty">
      <scm:attributeUse required="false" inheritable="false" ref="C123"/>
      <scm:attributeUse required="false" inheritable="false" ref="C140"/>
      <scm:attributeUse required="false" inheritable="false" ref="C136"/>
      <scm:finiteStateMachine initialState="0">
         <scm:state nr="0" final="true"/>
      </scm:finiteStateMachine>
   </scm:complexType>
   <scm:complexType id="C97"
                     base="#anyType"
                     derivationMethod="restriction"
                     abstract="false"
                     variety="empty">
      <scm:attributeUse required="false" inheritable="false" ref="C172"/>
      <scm:attributeUse required="false" inheritable="false" ref="C173" default="false">
         <scm:default lexicalForm="false">
            <scm:item type="#boolean" value="false"/>
         </scm:default>
      </scm:attributeUse>
      <scm:finiteStateMachine initialState="0">
         <scm:state nr="0" final="true"/>
      </scm:finiteStateMachine>
   </scm:complexType>
   <scm:complexType id="C98"
                     base="#string"
                     derivationMethod="extension"
                     abstract="false"
                     variety="simple"
                     simpleType="#string"/>
   <scm:complexType id="C99"
                     base="#string"
                     derivationMethod="extension"
                     abstract="false"
                     variety="simple"
                     simpleType="#string">
      <scm:attributeUse required="false" inheritable="false" ref="C174"/>
      <scm:attributeUse required="false" inheritable="false" ref="C5"/>
   </scm:complexType>
   <scm:complexType id="C100"
                     base="#string"
                     derivationMethod="extension"
                     abstract="false"
                     variety="simple"
                     simpleType="#string">
      <scm:attributeUse required="false" inheritable="false" ref="C175"/>
      <scm:attributeUse required="false" inheritable="false" ref="C5"/>
   </scm:complexType>
   <scm:complexType id="C102"
                     base="#string"
                     derivationMethod="extension"
                     abstract="false"
                     variety="simple"
                     simpleType="#string">
      <scm:attributeUse required="false" inheritable="false" ref="C138"/>
   </scm:complexType>
   <scm:complexType id="C103"
                     base="#string"
                     derivationMethod="extension"
                     abstract="false"
                     variety="simple"
                     simpleType="#string"/>
   <scm:complexType id="C105"
                     base="#anyType"
                     derivationMethod="restriction"
                     abstract="false"
                     variety="element-only">
      <scm:attributeUse required="false" inheritable="false" ref="C176"/>
      <scm:attributeUse required="false" inheritable="false" ref="C177"/>
      <scm:modelGroupParticle minOccurs="1" maxOccurs="1">
         <scm:sequence>
            <scm:elementParticle minOccurs="1" maxOccurs="unbounded" ref="C55"/>
            <scm:elementParticle minOccurs="1" maxOccurs="unbounded" ref="C178"/>
         </scm:sequence>
      </scm:modelGroupParticle>
      <scm:finiteStateMachine initialState="0">
         <scm:state nr="0">
            <scm:edge term="C55" to="1"/>
         </scm:state>
         <scm:state nr="1">
            <scm:edge term="C55" to="2"/>
            <scm:edge term="C178" to="3"/>
         </scm:state>
         <scm:state nr="2">
            <scm:edge term="C55" to="2"/>
            <scm:edge term="C178" to="3"/>
         </scm:state>
         <scm:state nr="3" final="true">
            <scm:edge term="C178" to="4"/>
         </scm:state>
         <scm:state nr="4" final="true">
            <scm:edge term="C178" to="4"/>
         </scm:state>
      </scm:finiteStateMachine>
   </scm:complexType>
   <scm:attribute id="C110"
                   name="ref"
                   type="#string"
                   global="false"
                   inheritable="false"/>
   <scm:attribute id="C112"
                   name="covers-30"
                   type="C52"
                   global="false"
                   inheritable="false"/>
   <scm:attribute id="C113"
                   name="covers-40"
                   type="C34"
                   global="false"
                   inheritable="false"/>
   <scm:attribute id="C115"
                   name="name"
                   type="#string"
                   global="false"
                   inheritable="false"/>
   <scm:attribute id="C117"
                   name="value"
                   type="#string"
                   global="false"
                   inheritable="false"/>
   <scm:attribute id="C123"
                   name="by"
                   type="#string"
                   global="false"
                   inheritable="false"/>
   <scm:attribute id="C125"
                   name="type"
                   type="C46"
                   global="false"
                   inheritable="false"/>
   <scm:attribute id="C130"
                   name="covers"
                   type="C47"
                   global="false"
                   inheritable="false"/>
   <scm:attribute id="C132"
                   name="document"
                   type="#anyURI"
                   global="false"
                   inheritable="false"/>
   <scm:attribute id="C134"
                   name="creator"
                   type="#string"
                   global="false"
                   inheritable="false"/>
   <scm:attribute id="C136"
                   name="change"
                   type="#string"
                   global="false"
                   inheritable="false"/>
   <scm:attribute id="C138"
                   name="code"
                   type="C50"
                   global="false"
                   inheritable="false"/>
   <scm:attribute id="C140"
                   name="on"
                   type="#date"
                   global="false"
                   inheritable="false"/>
   <scm:attribute id="C141"
                   name="prefix"
                   type="#anySimpleType"
                   global="false"
                   inheritable="false"
                   containingComplexType="C54"/>
   <scm:attribute id="C142"
                   name="uri"
                   type="#anySimpleType"
                   global="false"
                   inheritable="false"
                   containingComplexType="C54"/>
   <scm:attribute id="C143"
                   name="normalize-space"
                   type="#boolean"
                   global="false"
                   inheritable="false"
                   containingComplexType="C59"/>
   <scm:attribute id="C144"
                   name="name"
                   type="#QName"
                   global="false"
                   inheritable="false"
                   containingComplexType="C66"/>
   <scm:attribute id="C145"
                   name="select"
                   type="#string"
                   global="false"
                   inheritable="false"
                   containingComplexType="C66"/>
   <scm:attribute id="C146"
                   name="as"
                   type="#string"
                   global="false"
                   inheritable="false"
                   containingComplexType="C66"/>
   <scm:attribute id="C147"
                   name="source"
                   type="#string"
                   global="false"
                   inheritable="false"
                   containingComplexType="C66"/>
   <scm:attribute id="C148"
                   name="declared"
                   type="#boolean"
                   global="false"
                   inheritable="false"
                   containingComplexType="C66"/>
   <scm:attribute id="C149"
                   name="idref"
                   type="#NCName"
                   global="false"
                   inheritable="false"
                   containingComplexType="C69"/>
   <scm:attribute id="C150"
                   name="section-number"
                   type="C49"
                   global="false"
                   inheritable="false"
                   containingComplexType="C69"/>
   <scm:attribute id="C151"
                   name="select"
                   type="#string"
                   global="false"
                   inheritable="false"
                   containingComplexType="C75"/>
   <scm:attribute id="C152"
                   name="name"
                   type="#QName"
                   global="false"
                   inheritable="false"
                   containingComplexType="C81"/>
   <scm:attribute id="C153"
                   name="decimal-separator"
                   type="C38"
                   global="false"
                   inheritable="false"
                   containingComplexType="C81"/>
   <scm:attribute id="C154"
                   name="grouping-separator"
                   type="C38"
                   global="false"
                   inheritable="false"
                   containingComplexType="C81"/>
   <scm:attribute id="C155"
                   name="zero-digit"
                   type="C38"
                   global="false"
                   inheritable="false"
                   containingComplexType="C81"/>
   <scm:attribute id="C156"
                   name="digit"
                   type="C38"
                   global="false"
                   inheritable="false"
                   containingComplexType="C81"/>
   <scm:attribute id="C157"
                   name="minus-sign"
                   type="C38"
                   global="false"
                   inheritable="false"
                   containingComplexType="C81"/>
   <scm:attribute id="C158"
                   name="percent"
                   type="C38"
                   global="false"
                   inheritable="false"
                   containingComplexType="C81"/>
   <scm:attribute id="C159"
                   name="per-mille"
                   type="C38"
                   global="false"
                   inheritable="false"
                   containingComplexType="C81"/>
   <scm:attribute id="C160"
                   name="pattern-separator"
                   type="C38"
                   global="false"
                   inheritable="false"
                   containingComplexType="C81"/>
   <scm:attribute id="C161"
                   name="exponent-separator"
                   type="C38"
                   global="false"
                   inheritable="false"
                   containingComplexType="C81"/>
   <scm:attribute id="C162"
                   name="infinity"
                   type="#string"
                   global="false"
                   inheritable="false"
                   containingComplexType="C81"/>
   <scm:attribute id="C163"
                   name="NaN"
                   type="#string"
                   global="false"
                   inheritable="false"
                   containingComplexType="C81"/>
   <scm:attribute id="C164"
                   name="xslt-location"
                   type="#anySimpleType"
                   global="false"
                   inheritable="false"
                   containingComplexType="C85"/>
   <scm:attribute id="C165"
                   name="xquery-location"
                   type="#anySimpleType"
                   global="false"
                   inheritable="false"
                   containingComplexType="C85"/>
   <scm:attribute id="C166"
                   name="file"
                   type="#anyURI"
                   global="false"
                   inheritable="false"
                   containingComplexType="C87"/>
   <scm:attribute id="C167"
                   name="update"
                   type="#boolean"
                   global="false"
                   inheritable="false"
                   containingComplexType="C87"/>
   <scm:attribute id="C168"
                   name="satisfied"
                   type="#boolean"
                   global="false"
                   inheritable="false"
                   containingComplexType="C90"/>
   <scm:attribute id="C169"
                   name="uri"
                   type="#anyURI"
                   global="false"
                   inheritable="false"
                   containingComplexType="C94"/>
   <scm:attribute id="C170"
                   name="location"
                   type="#anyURI"
                   global="false"
                   inheritable="false"
                   containingComplexType="C94"/>
   <scm:attribute id="C171"
                   name="file"
                   type="#anyURI"
                   global="false"
                   inheritable="false"
                   containingComplexType="C94"/>
   <scm:attribute id="C172"
                   name="uri"
                   type="C0"
                   global="false"
                   inheritable="false"
                   containingComplexType="C97"/>
   <scm:attribute id="C173"
                   name="default"
                   type="#boolean"
                   global="false"
                   inheritable="false"
                   containingComplexType="C97"/>
   <scm:attribute id="C174"
                   name="ignore-prefixes"
                   type="#boolean"
                   global="false"
                   inheritable="false"
                   containingComplexType="C99"/>
   <scm:attribute id="C175"
                   name="flags"
                   type="#string"
                   global="false"
                   inheritable="false"
                   containingComplexType="C100"/>
   <scm:attribute id="C176"
                   name="version"
                   type="#decimal"
                   global="false"
                   inheritable="false"
                   containingComplexType="C105"/>
   <scm:attribute id="C177"
                   name="test-suite"
                   type="#string"
                   global="false"
                   inheritable="false"
                   containingComplexType="C105"/>
   <scm:element id="C178"
                 name="test-set"
                 targetNamespace="http://www.w3.org/2010/09/qt-fots-catalog"
                 type="C179"
                 global="false"
                 containingComplexType="C105"
                 nillable="false"
                 abstract="false"/>
   <scm:complexType id="C179"
                     base="C4"
                     derivationMethod="extension"
                     abstract="false"
                     variety="empty">
      <scm:attributeUse required="false" inheritable="false" ref="C115"/>
      <scm:attributeUse required="false" inheritable="false" ref="C5"/>
      <scm:attributeUse required="false" inheritable="false" ref="C9"/>
      <scm:finiteStateMachine initialState="0">
         <scm:state nr="0" final="true"/>
      </scm:finiteStateMachine>
   </scm:complexType>
</scm:schema>
<?Σ 5c2272b0?>
