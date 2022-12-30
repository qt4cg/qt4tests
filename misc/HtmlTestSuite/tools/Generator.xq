xquery version "3.1";

(: This query generates a set of test cases that test the individual HTML5 files
   in directory files. It relies on fn:uri-collection being able to read the directory
   contents. 
 :)


<test-set xmlns="http://www.w3.org/2010/09/qt-fots-catalog" name="misc-HtmlTestSuite" covers40="fn-parse-html">
   <description>Tests selected from the Html5 Test Suite (https://github.com/web-platform-tests/wpt). See tools/readme.md.</description>
   <link type="spec" document="FuncOps" section-number="7.1" idref="string-types"/>
   
  {for $uri in uri-collection('../files?select=*.html')
   let $name := tokenize($uri, '/')[last()] => substring-before('.html')
   order by $name
   return

   <test-case name="html-{$name}">
      <description>HtmlTestSuite test case {$name}</description>
      <created by="Michael Kay, Saxonica" on="{current-date()}"/>
      <module uri="http://www.w3.org/qt4cg/compare" file="HtmlTestSuite/modules/compare.xquery"/>
      <dependency type="spec" value="XQ40+"/>
      <test>
         import module namespace cmp="http://www.w3.org/qt4cg/compare";
         cmp:compare(parse-html(unparsed-text('HtmlTestSuite/files/{$name}.html')), doc('HtmlTestSuite/results/{$name}.xhtml'))</test>
      <result>
         <assert-true/>
      </result>
   </test-case>
  }
</test-set>