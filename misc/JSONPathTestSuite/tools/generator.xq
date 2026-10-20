(:~
 : Generates misc/JSONPathTestSuite.xml from the JSONPath Compliance Test Suite (RFC 9535).
 : Each JSONPath query is translated to XQuery 4.0 and kept if its result
 : matches the expected JSONPath result. Idiomatic code is preferred to strict code.
 :
 : @author Christian Gruen, BaseX
 :)
import module namespace translate = 'http://www.w3.org/qt4cg/jsonpath/translate' at 'translate.xqm';

(:~ URI of cts.json of the JSONPath Compliance Test Suite. :)
declare variable $cts external :=
  'https://raw.githubusercontent.com/jsonpath-standard/jsonpath-compliance-test-suite/main/cts.json';

declare variable $TARGET := file:resolve-path('../../JSONPathTestSuite.xml', file:base-dir());
declare variable $REPORT := file:resolve-path('JSONPathTestSuite-report.txt', file:temp-dir());
declare variable $NL := char('\n');
(:~ Maximum width of an input line. :)
declare variable $WIDTH := 100;
declare variable $TODAY := format-date(current-date(), '[Y0001]-[M01]-[D01]');
(:~ Test cases of the existing test set. :)
declare variable $EXISTING := if (file:exists($TARGET)) then doc($TARGET)//*:test-case;

(:~
 : Returns a test case, with the creation date of the existing test case if nothing else has changed.
 : @param $new  new test case
 : @return test case
 :)
declare function revised(
  $new  as element()
) as element() {
  let $old := $EXISTING[@name = $new/@name]
  let $content := fn($test) { $test/(* except *:created) }
  return if (exists($old) and
    deep-equal($content($old), $content($new), options := { 'whitespace': 'strip' })) then (
    element { node-name($new) } { $new/@*, $new/* ! (if (self::*:created) then $old/*:created else .) }
  ) else (
    $new
  )
};

(:~
 : Evaluates a query and returns errors as maps.
 : @param $query  query string
 : @return result or error map
 :)
declare function eval(
  $query  as xs:string
) as item()* {
  try {
    load-xquery-module('urn:q', {
      'content': `module namespace q = 'urn:q'; declare variable $q:result := ({ $query });`
    })?variables?(QName('urn:q', 'result'))
  } catch * {
    $err:map
  }
};

(:~
 : Returns the normalized JSONPath of a JNode.
 : @param $node  JNode
 : @return normalized path
 :)
declare function normalized-path(
  $node  as jnode()
) as xs:string {
  `${ string-join($node/ancestor-or-self::jnode() ! jkey() ! (
    if (. instance of xs:integer) then (
      `[{ . - 1 }]`
    ) else (
      `['{
        . => replace('\\', '\\\\') => replace("'", "\\'") => replace('\n', '\\n')
          => replace('\r', '\\r') => replace('\t', '\\t')
      }']`
    )
  )) }`
};

(:~
 : Checks if the input must be converted to a JNode.
 : @param $input  input
 : @param $code   code that references the input
 : @return result of check
 :)
declare function needs-jtree(
  $input  as item()?,
  $code   as xs:string
) as xs:boolean {
  (: maps and arrays are converted to JNodes by a path expression :)
  not($input instance of (map(*) | array(*))?) or matches($code, '\$in(?!/)')
};

(:~
 : Returns an expression for a JSON value; maps and arrays that exceed the line width get one entry per line.
 : @param $value   value
 : @param $indent  indentation of the current line
 : @return code
 :)
declare function literal(
  $value   as item()?,
  $indent  as xs:string
) as xs:string {
  let $line := translate:literal($value)
  return if (string-length($indent) + string-length($line) <= $WIDTH or
    not($value instance of (map(*) | array(*)))) then (
    $line
  ) else (
    let $inner := $indent || '  '
    let $entries := if ($value instance of map(*)) then (
      map:for-each($value, fn($k, $v) { `{ translate:string($k) }: { literal($v, $inner) }` })
    ) else (
      for member $m in $value return literal($m, $inner)
    )
    let $brackets := if ($value instance of map(*)) then ('{', '}') else ('[', ']')
    return string-join((
      $brackets[1],
      string-join($entries ! ($inner || .), ',' || $NL),
      $indent || $brackets[2]
    ), $NL)
  )
};

(:~
 : Returns a query that binds the input and evaluates the specified code.
 : @param $input  input
 : @param $code   code
 : @return query
 :)
declare function query(
  $input  as item()?,
  $code   as xs:string
) as xs:string {
  let $jtree := if (needs-jtree($input, $code)) then ' => jtree()' else ''
  return `let $in := { literal($input, '') }{ $jtree }{ $NL }return { $code }`
};

(:~
 : Creates a test case name from the name of a CTS test.
 : @param $name  name of the CTS test
 : @return test case name
 :)
declare function test-name(
  $name  as xs:string
) as xs:string {
  `JSONPath-{
    $name
    => replace('\|\|', ' or ') => replace('&amp;&amp;', ' and ') => replace('==', ' eq ')
    => replace('!=', ' ne ') => replace('<=', ' le ') => replace('>=', ' ge ')
    => replace('<', ' lt ') => replace('>', ' gt ')
    => replace('(^|\s)-(\d)', '$1minus $2') => replace('(^|\s)\+(\d)', '$1plus $2')
    => replace('\p{So}', fn($m) { ` { format-integer(string-to-codepoints($m), '16^X') } ` })
    => replace('[^\p{L}\p{N}]+', '-') => replace('^-|-$', '')
  }`
};

let $cases := (
  for $case in json-doc($cts)?tests?*
  let $outcome := try {
    if ($case?invalid_selector) { translate:skip('invalid selector') },
    let $ast := translate:parse($case?selector)
    let $input := $case?document
    (: results: no node, a single null, or no null values → nodes; otherwise → array :)
    let $alternatives := $case?result otherwise $case?results?*
    let $none := exists($case?result[array:empty(.)])
    let $null := exists($case?result[array:size(.) = 1 and empty(?*)])
    let $sequence := not($none) and
      (every $a in $alternatives satisfies array:size($a) = count($a?*))
    let $single := $sequence and (
      every $a in $alternatives satisfies $a?* instance of xs:anyAtomicType
    )
    let $expected := switch () {
      case $none return '()'
      (: single atomic values are compared with eq, which atomizes the JNode :)
      case $single return $alternatives ! translate:literal(?*)
      (: JNodes are compared by their values :)
      case $sequence return $alternatives ! string-join(?* ! `jtree({ translate:literal(.) })`, ', ')
      default return $alternatives ! translate:literal(.)
    }
    let $wanted := $expected ! array { eval(.) }
    let $arrays := $alternatives ! translate:literal(.) ! eval(.)
    let $paths := $case?result_paths otherwise $case?results_paths?*
    let $nodes := $none or $null or $sequence
    let $results := (
      for $mode in ('idiomatic', 'mixed', 'strict')
      let $code := translate:translate($ast, $mode, $input)
      (: the array of all selected values is verified, and the result of the test query :)
      let $array-query := query($input, `array:of-members({ $code })`)
      let $query := if ($nodes) then query($input, $code) else $array-query
      let $array := eval($array-query)
      let $got := if ($nodes) then eval($query) else $array
      return {
        'mode': $mode, 'code': $code, 'query': $query, 'got': $array,
        'ok': (some $a in $arrays satisfies deep-equal($array, $a)) and (
          switch () {
            case $null return $got instance of jnode(*, empty-sequence())
            case $single return some $w in $wanted satisfies (try { $got eq $w?* } catch * { false() })
            default return some $w in $wanted satisfies deep-equal($got, $w?*)
          }
        )
      }
    )
    let $ok := head($results[?ok])
    return if (exists($ok)) then (
      {
        'mode': $ok?mode, 'query': $ok?query, 'expected': $expected, 'wanted': $wanted,
        'null': $null,
        'idiomatic': $results[1],
        'paths': (
          let $got := eval(query($input, `array:build({ $results[?mode = 'strict']?code })`))
          return $got instance of array(jnode()) and
            (some $p in $paths satisfies deep-equal(array:for-each($got, normalized-path#1), $p))
        )
      }
    ) else (
      { 'mismatch': $results }
    )
  } catch translate:skip {
    { 'skip': $err:description }
  } catch * {
    { 'skip': `error: { $err:code } { $err:description }` }
  }
  return map:merge(({ 'name': test-name($case?name), 'case': $case }, $outcome))
) -> (
  if (all-different(?name)) then . else error((), `Duplicate test names: { duplicate-values(?name) }`)
)
let $verified := $cases[?query]
let $test-set :=
  <test-set xmlns="http://www.w3.org/2010/09/qt-fots-catalog" name="misc-JSONPathTestSuite"
      covers-40="PR2031 PR2083">
    <description>Tests derived from the JSONPath Compliance Test Suite (https://github.com/jsonpath-standard/jsonpath-compliance-test-suite), translated to XQuery 4.0 with JNodes.</description>
    <link type="spec" document="XQuery" section-number="4.6" idref="id-path-expressions"/>
    <dependency type="spec" value="XQ40+"/>
    {
      for $test in $verified
      return revised(<test-case name="{ $test?name }">
        <description>{ $test?case?name }: { $test?case?selector }</description>
        <created by="Christian Grün" on="{ $TODAY }"/>
        <test>{ `{ $NL }{ $test?query }{ $NL }` }</test>
        <result>{
          (: results are JNodes: a single atomic value is compared with eq, including booleans :)
          let $assert := fn($literal as xs:string, $value as item()*) as element() {
            switch () {
              case empty($value) return <assert-empty/>
              case $value instance of xs:anyAtomicType return <assert-eq>{ $literal }</assert-eq>
              default return <assert-deep-eq>{ $literal }</assert-deep-eq>
            }
          }
          return switch () {
            case $test?null return <assert-type>jnode(*, empty-sequence())</assert-type>
            case count($test?expected) = 1 return $assert($test?expected, $test?wanted?*)
            default return
              <any-of>{ for $e at $i in $test?expected return $assert($e, $test?wanted[$i]?*) }</any-of>
          }
        }</result>
      </test-case>)
    }
  </test-set>
let $skipped := $cases[?skip]
let $mismatches := $cases[exists(?mismatch)]
let $strict := $verified[?mode = 'strict']
let $adaptive := serialize(?, { 'method': 'adaptive' })
let $report := (
  `Cases: { count($cases) }`,
  `Verified: { count($verified) } (idiomatic: { count($verified[?mode = 'idiomatic']) }, mixed: { count($verified[?mode = 'mixed']) }, strict only: { count($strict) })`,
  `Normalized paths verified: { count($verified[?paths]) }`,
  `Mismatches: { count($mismatches) }`,
  `Skipped: { count($skipped) }`,
  '',
  for $s in $skipped
  group by $reason := replace($s?skip, ':.*', '')
  order by count($s) descending
  return `{ count($s) } { $reason }`,
  '',
  '== MISMATCHES ==',
  for $m in $mismatches
  return (
    `{ $m?name }: { $m?case?selector }`,
    for $r in $m?mismatch
    return (`  { $r?mode }: { $r?code }`, `    => { $adaptive($r?got) }`),
    ''
  ),
  '== STRICT ONLY ==',
  for $s in $strict
  return (
    `{ $s?name }: { $s?case?selector }`,
    `  idiomatic: { $s?idiomatic?code }`,
    `    => { $adaptive($s?idiomatic?got) }`,
    `  expected: { string-join($s?expected, ' | ') }`,
    ''
  ),
  '== SKIPPED ==',
  $skipped[?skip != 'invalid selector'] ! `{ ?skip }: { ?case?selector }`,
  '',
  '== PATH MISMATCHES ==',
  $verified[not(?paths)] ! `{ ?name }: { ?case?selector }`
)
return (
  file:write($TARGET, $test-set, {
    'indent': true(),
    'omit-xml-declaration': false(),
    'cdata-section-elements': QName('http://www.w3.org/2010/09/qt-fots-catalog', 'test')
  }),
  file:write-text-lines($REPORT, $report),
  subsequence($report, 1, 5),
  `Report: { $REPORT }`
)
