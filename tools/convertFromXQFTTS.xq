(:~
 : Converts the XQuery and XPath Full Text 1.0 Test Suite (XQFTTS) into QT4 test sets.
 : The test sets and the referenced test sources are written to the ft/ directory,
 : the catalog entries are returned as result.
 :
 : @author Christian Gruen
 :)
declare default element namespace 'http://www.w3.org/2010/09/qt-fots-catalog';
declare namespace ft = 'http://www.w3.org/2005/02/query-test-full-text';

(:~ Directory of the XQFTTS. :)
declare variable $XQFTTS external := file:base-dir() || '../../xqftts/';
(:~ Target directory. :)
declare variable $TARGET external := file:base-dir() || '../ft/';
(:~ Date of the conversion. :)
declare variable $TODAY external := string(current-date() => adjust-date-to-timezone(()));

(:~ XQFTTS catalog. :)
declare variable $CATALOG := doc($XQFTTS || 'XQFTTSCatalog.xml')/ft:test-suite;

(:~ Default stop words and thesauri. :)
declare variable $DEFAULTS := $CATALOG//(ft:stopwords, ft:thesaurus)[@uri = '##default']/@ID;

(:~ Tests that treat element boundaries as sentence and paragraph boundaries. :)
declare variable $UNITS := (
  'FTScope-q3', 'FTScope-q4', 'FTScope-unconstrained-q3', 'FTScope-unconstrained-q4',
  'FTWindow-paragraphs1', 'FTWindow-paragraphs3',
  'FTWindow-unconstrained-paragraphs1', 'FTWindow-unconstrained-paragraphs3',
  'examples-364-2', 'unconstrained-examples-364-2'
);

(:~ Corrected results that contradicted the formal semantics of FTWindow. :)
declare variable $CORRECTIONS := map:merge(
  for $name in ('FTNot-q6', 'FTNot-unconstrained-q6', 'FTNot-q6-unconstrained-window')
  return map:entry($name, <assert-xml>{ '<title>Ninja Coder</title>' }</assert-xml>)
);

(:~ Serialization parameters. :)
declare variable $PARAMS := {
  'indent': true(),
  'cdata-section-elements': ('test', 'assert-xml') !
    QName('http://www.w3.org/2010/09/qt-fots-catalog', .)
};

(:~
 : Returns the query string of a test case.
 : @param $test test case
 : @return query string
 :)
declare function local:query($test as element(ft:test-case)) as xs:string {
  file:read-text($XQFTTS || 'Queries/XQuery/' ||$test/@FilePath || $test/ft:query/@name || '.xq')
  => replace('\(: insert-(start|end) :\)[ \t]*\n?', '')
  => replace('^\s+|\s+$', '')
  => replace('\n([ \t]*\n)+', '&#xa;')
  => replace('"(\.\./)+XQFTTSCatalog.xml"', '"TestSources/XQFTTSCatalog.xml"')
};

(:~
 : Returns the environment of a test case.
 : @param $test test case
 : @param $query query string
 : @return environment
 :)
declare function local:environment(
  $test as element(ft:test-case),
  $query as xs:string
) as element(environment)? {
  let $sources := (
    for $input in $test/ft:input-file
    let $role := '$' || $input/@variable
    return <source role='{ $role }' file='{ local:source($input) }'>{
      if(contains($query, 'declare variable ' || $role)) { attribute declared { 'true' } }
    }</source>,
    for $input in $test/ft:contextItem
    return <source role='.' file='{ local:source($input) }'/>
  )
  let $resources := (
    for $resource in $CATALOG//(ft:stopwords, ft:thesaurus)
    where contains($query, '"' || $resource/@uri || '"')
    return <resource uri='{ $resource/@uri }' file='{ local:copy($resource/@FileName) }'/>
  )
  where exists(($sources, $resources))
  return <environment>{ $sources, $resources }</environment>
};

(:~
 : Returns the path to the source document of an input.
 : @param $input input
 : @return path
 :)
declare function local:source($input as element()) as xs:string {
  local:copy($CATALOG//ft:source[@ID = $input]/@FileName)
};

(:~
 : Copies a test source to the target directory.
 : @param $path path to the test source
 : @return path to the copied file
 :)
declare function local:copy($path as xs:string) as xs:string {
  let $file := 'TestSources/' || replace($path, '^TestSources/', '')
  return (
    if(file:exists($XQFTTS || $path)) {
      file:create-dir($TARGET || 'TestSources'),
      file:copy($XQFTTS || $path, $TARGET || $file)
    },
    $file
  )
};

(:~
 : Returns the result assertion of an output file.
 : @param $output output file
 : @return assertion
 :)
declare function local:assertion($output as element(ft:output-file)) as element() {
  let $result := file:read-text($XQFTTS || 'ExpectedTestResults/' ||$output/../@FilePath || $output)
  let $string := normalize-space($result)
  return switch() {
    case $output/@compare = ('Inspect', 'Ignore') return
      <assert>$result instance of item()* (: any non-error result is OK :)</assert>
    case $string = '' return <assert-empty/>
    case $string = 'true' return <assert-true/>
    case $string = 'false' return <assert-false/>
    case $output/@compare = 'Text' and not(contains($result, '<')) return
      <assert-string-value>{ $result => replace('\n$', '') }</assert-string-value>
    default return
      <assert-xml>{ $result => replace('^<\?xml.*?\?>\s*', '') => replace('\s+$', '') }</assert-xml>
  }
};

(:~
 : Returns the implementation-defined or optional features required by a test case.
 : @param $test test case
 : @param $query query string
 : @return features
 :)
declare function local:features(
  $test as element(ft:test-case),
  $query as xs:string
) as xs:string* {
  if($test/ft:aux-URI = $DEFAULTS or contains($query, 'stop words default')) {
    'fullText-defaults'
  },
  if(contains($query, 'without content') and not($test/ft:expected-error = 'FTST0007')) {
    'fullText-ignore'
  },
  if($test/@name = $UNITS) { 'fullText-units' }
};

(:~
 : Converts a test case.
 : @param $test test case
 : @return converted test case
 :)
declare function local:test-case($test as element(ft:test-case)) as element(test-case) {
  let $query := local:query($test)
  let $corrected := $CORRECTIONS($test/@name)
  let $results := (
    if(exists($corrected)) { $corrected } else { $test/ft:output-file ! local:assertion(.) },
    $test/ft:expected-error ! <error code='{ normalize-space() }'/>
  )
  return <test-case name='{ replace($test/@name, '^Catalog', 'ft-Catalog') }'>
    <description>{ normalize-space($test/ft:description) }</description>
    <created by='{ $test/@Creator }' on='{ $test/ft:query/@date }'/>
    <modified by='Christian Gruen' on='{ $TODAY }'
      change='converted from original XQFTTS test { $test/@name }'/>
    {
      if(exists($corrected)) {
        <modified by='Christian Gruen' on='{ $TODAY }'
          change='excludes outside the window are ignored'/>
      }
    }
    { local:environment($test, $query) }
    {
      local:features($test, $query) ! <dependency type='feature' value='{ . }'/>
    }
    <test>{ $query }</test>
    <result>{
      switch(count($results)) {
        case 0 return <assert>$result instance of item()* (: any non-error result is OK :)</assert>
        case 1 return $results
        default return <any-of>{ $results }</any-of>
      }
    }</result>
  </test-case>
};

file:create-dir($TARGET),
for $group in $CATALOG//ft:test-group[ft:test-case]
let $name := replace($group/@name, ' ')
let $set := <test-set name='ft-{ $name }'>
  <description>{
    let $info := $group/ft:GroupInfo/(ft:title, ft:description)[normalize-space()]
    return string-join(('XQuery Full Text', $info), ' - ')
  }</description>
  <dependency type='spec' value='XQ10+'/>
  <dependency type='feature' value='fullText'/>
  { $group/ft:test-case ! local:test-case(.) }
</test-set>
return (
  file:write($TARGET || $name || '.xml', $set, $PARAMS),
  `    { pad-string(`<test-set name="ft-{ $name }" `, 52) }file="ft/{ $name }.xml"/>`
)
