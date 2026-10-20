(:~
 : Generates misc/JMESPathTestSuite.xml from the JMESPath compliance tests.
 : Each JMESPath expression is translated to XQuery 4.0 and kept if its result
 : matches the expected JMESPath result. Idiomatic code is preferred to strict code.
 :
 : @author Christian Gruen, BaseX
 :)
import module namespace translate = 'http://www.w3.org/qt4cg/jmespath/translate' at 'translate.xqm';

(:~ GitHub API URI of the tests directory of the JMESPath compliance tests. :)
declare variable $suite external :=
  'https://api.github.com/repos/jmespath/jmespath.test/contents/tests';

declare variable $TARGET := file:resolve-path('../../JMESPathTestSuite.xml', file:base-dir());
declare variable $REPORT := file:resolve-path('JMESPathTestSuite-report.txt', file:temp-dir());
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

let $cases := (
  for $entry in sort(json-doc($suite)?*[ends-with(?name, '.json')], key := fn { ?name })
  let $file := $entry?name
  let $base := replace($file, '\.json$', '')
  for $group at $g in json-doc($entry?download_url)?*
  for $case at $c in $group?cases?*
  let $outcome := try {
    if (map:contains($case, 'error')) { translate:skip('error case') },
    if (not(map:contains($case, 'result'))) { translate:skip('no result') },
    let $ast := translate:parse($case?expression)
    let $input := $group?given
    let $result := $case?result
    let $wanted := eval(`[ ({ translate:literal($result) }) ]`)
    let $results := (
      for $mode in ('idiomatic', 'mixed', 'strict')
      let $translation := translate:translate($ast, $mode, $result instance of xs:anyAtomicType, $input)
      (: projections without null values: sequence of JNodes :)
      let $sequence := exists($translation?nodes) and
        exists($result[. instance of array(*)][array:size(.) = count(?*)])
      (: a value selected by a path: JNode :)
      let $node := not($sequence) and exists($translation?node) and exists($result)
      (: null selected by a path: no JNode, or a JNode with a null value :)
      let $null := empty($result) and exists($translation?node)
      let $selected := if ($null) then eval(query($input, $translation?node)) else ()
      (: a single atomic value in a JNode: compared with eq, which atomizes the JNode :)
      let $atomic := ($node and $result instance of xs:anyAtomicType) or
        ($sequence and array:size($result) = 1 and $result?* instance of xs:anyAtomicType)
      let $code := switch () {
        case $sequence return $translation?nodes
        case $node or $null return $translation?node
        default return $translation?code
      }
      (: JNodes are compared by their values :)
      let $expected := switch () {
        case $null return '()'
        case $sequence and empty($result?*) return '()'
        case $atomic return translate:literal(if ($sequence) then $result?* else $result)
        case $sequence return string-join($result?* ! `jtree({ translate:literal(.) })`, ', ')
        case $node return `jtree({ translate:literal($result) })`
        default return translate:literal($result)
      }
      (: the complete result is verified, and the result of the test query :)
      let $full := eval(query($input, `[ ({ $translation?code }) ]`))
      let $got := if ($code = $translation?code) then $full else eval(query($input, `[ ({ $code }) ]`))
      return {
        'mode': $mode, 'code': $code, 'got': $full, 'expected': $expected,
        'value': if ($sequence) then $result?* else $result,
        'null-node': exists($selected), 'atomic': $atomic,
        'ok': $full instance of array(*) and
          deep-equal($full, $wanted) and (
            switch () {
              case exists($selected) return $selected instance of jnode(*, empty-sequence())
              case $atomic return count($got?*) = 1 and
                (try { $got?* eq eval($expected) } catch * { false() })
              default return deep-equal($got, eval(`[ ({ $expected }) ]`))
            }
          )
      }
    )
    let $ok := head($results[?ok])
    return if (exists($ok)) then (
      {
        'mode': $ok?mode, 'query': query($input, translate:unwrap($ok?code)),
        'expected': $ok?expected,
        'value': $ok?value, 'null-node': $ok?null-node, 'atomic': $ok?atomic,
        'idiomatic': $results[1]
      }
    ) else (
      { 'expected': $results[1]?expected, 'mismatch': $results }
    )
  } catch translate:skip {
    { 'skip': $err:description }
  } catch * {
    { 'skip': `error: { $err:code } { $err:description }` }
  }
  return map:merge((
    { 'name': `JMESPath-{ $base }-{ $g }-{ $c }`, 'file': $file, 'case': $case }, $outcome
  ))
)
let $verified := $cases[?query]
let $test-set :=
  <test-set xmlns="http://www.w3.org/2010/09/qt-fots-catalog" name="misc-JMESPathTestSuite"
      covers-40="PR2031 PR2083">
    <description>Tests derived from the JMESPath compliance tests (https://github.com/jmespath/jmespath.test), translated to XQuery 4.0 with JNodes.</description>
    <link type="spec" document="XQuery" section-number="4.6" idref="id-path-expressions"/>
    <dependency type="spec" value="XQ40+"/>
    {
      for $test in $verified
      return revised(<test-case name="{ $test?name }">
        <description>{ $test?file }: { $test?case?expression }</description>
        <created by="Christian Grün" on="{ $TODAY }"/>
        <test>{ `{ $NL }{ $test?query }{ $NL }` }</test>
        <result>{
          let $value := $test?value
          return switch () {
            case $test?null-node return <assert-type>jnode(*, empty-sequence())</assert-type>
            (: JNode with an atomic value: compared with eq, including booleans :)
            case $test?atomic return <assert-eq>{ $test?expected }</assert-eq>
            case empty($value) return <assert-empty/>
            case $value instance of xs:boolean return if ($value) then <assert-true/> else <assert-false/>
            case $value instance of xs:anyAtomicType return <assert-eq>{ $test?expected }</assert-eq>
            default return <assert-deep-eq>{ $test?expected }</assert-deep-eq>
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
    `{ $m?name }: { $m?case?expression }`,
    for $r in $m?mismatch
    return (`  { $r?mode }: { $r?code }`, `    => { $adaptive($r?got) }`),
    `  expected: { $m?expected }`,
    ''
  ),
  '== STRICT ONLY ==',
  for $s in $strict
  return (
    `{ $s?name }: { $s?case?expression }`,
    `  idiomatic: { $s?idiomatic?code }`,
    `    => { $adaptive($s?idiomatic?got) }`,
    `  expected: { $s?expected }`,
    ''
  ),
  '== SKIPPED ==',
  $skipped[not(?skip = ('error case', 'no result'))] ! `{ ?skip }: { ?case?expression }`
)
return (
  file:write($TARGET, $test-set, {
    'indent': true(),
    'omit-xml-declaration': false(),
    'cdata-section-elements': QName('http://www.w3.org/2010/09/qt-fots-catalog', 'test')
  }),
  file:write-text-lines($REPORT, $report),
  subsequence($report, 1, 4),
  `Report: { $REPORT }`
)
