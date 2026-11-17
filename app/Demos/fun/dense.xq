(:~ Dense: as much XQuery 4.0 per line as possible. :)
declare namespace z = 'z';

declare type z:k as enum('a', 'b');

declare record z:p(
  x as xs:double,
  y as xs:double := 0,
  %fixed n as fn(z:p) as xs:double := fn { math:sqrt(?x × ?x + ?y × ?y) }
) where ?x >= 0;

declare record z:q extends z:p(
  k as z:k := 'a'
);

declare record pair(l, r := ());

declare function z:j(
  $s as item()*,
  $t as xs:string := ' '
) as xs:string {
  string-join($s, $t)
};

let $p := z:q(3, 4) but with { 'k': 'b' }
let ${ $x, $k } := $p
let $( $a, $b ) := (0x1F, 0b101)
let $[ $h ] := [ 1_000 ]
let $j := { 'a': [ 1, { 'b': 2 } ] }
let $s := (3, 1, 4, 1, 5, 9, 2, 6)
return (
  (: records, methods, destructuring, braces in templates :)
  `{ $p =?> n() }{ $k }{{{ $x }}}`,

  (: FLWOR: for key/value, count, while :)
  z:j(
    for key $c value $v in map:build(characters('ouroboros'), value := fn { 1 })
    order by count($v) descending, $c
    count $i
    while $i < 3
    return `{ $c }{ count($v) }`
  ),

  (: for member over an array of sequences :)
  z:j(
    for member $m in array:build(1 to 3, fn { (., . × .) })
    return foot($m)
  ),

  (: pipelines, mapping arrows, keyword arguments :)
  (1 to 9)
    -> scan(., 0, op('+'))
    =!> array:get(1)
    -> slice(., start := 2, step := 3)
    -> z:j(.),

  (: Collatz trail of 27 :)
  while-do(
    27,
    fn { foot(.) != 1 },
    fn { ., foot(.) -> (if (. mod 2) then 3 × . + 1 else . idiv 2) }
  ) -> `{ count(.) - 1 }↑{ highest(.) }`,

  (: sequence functions :)
  $s -> (
    duplicate-values(.),
    index-where(., fn { . > 4 }),
    all-different(.),
    every(., fn { . > 0 }),
    lowest(., (), fn { -. })
  ) -> z:j(.),

  (: braced switch without operand :)
  $s ! (
    switch () {
      case . > 4 return '+'
      case . = 1 return '1'
      default return '-'
    }
  ) -> z:j(., t := ''),

  (: characters, separators :)
  insert-separator(characters('xq' || $b - 1) =!> upper-case(), '·') -> z:j(., ''),

  (: radix pictures, character names :)
  `{ format-integer($a × $b, '2^xxxx_xxxx') } { parse-integer('zz', 36) } {
    (char(0x3A9), char('rarr'), char('amp')) -> z:j(., '')
  }`,

  (: but with on a built-in record :)
  (parts-of-dateTime(xs:date('2026-11-17+01:00')) but with { 'timezone': () })
    => build-dateTime(),

  (: node functions :)
  <r><a/><b x='1'>2</b><c/></r>/b -> (
    siblings(.) ! name(),
    transitive-closure(.., fn { * }) ! name(),
    element-to-map(.)?b => map:keys()
  ) -> z:j(.),

  (: ixml :)
  invisible-xml('s: d++-",". d: ["0"-"9"]+.')(`{ $a },{ $b }`)//d => sum(),

  (: JNodes, decimal division, otherwise, map functions :)
  (
    $j//b,
    $j/a/*/b,
    $j/a/1,
    divide-decimals(10, 3)?*,
    () otherwise $h,
    map:filter({ 'a': 1, 'b': 2 }, fn($k, $v) { $v > 1 }) => map:keys()
  ) -> z:j(.),

  (: trace clause, computed node test, namespace axis, named groups :)
  z:j(
    for $n in <r xmlns:p='u'><a/><b/></r>/child::{ 'b' }
    trace `visiting { name($n) }`
    return (
      name($n),
      $n/namespace::p ! string(),
      matches('abab', '^(?<p>ab)\k<p>$')
    )
  ),

  (: iterating several arrays and maps, record casts, no-namespace records, recent functions :)
  (
    for member $m in ([ 1, 2 ], [ 3 ]) return sum($m),
    for key $key value $v in ({ 'a': 1 }, { 'b': 2 }) return `{ $key }{ $v }`,
    ({ 'x': 3, 'q': 0 } cast as z:p) => map:keys(),
    pair(1)?l,
    element-to-map(<b x='1'>2</b>) => map-to-element() => name(),
    deep-equal(z:j#2, z:j#2),
    () instance of xs:error?
  ) -> z:j(.),

  (: reflection :)
  (1, 'a', [ 1 ], {}, fn {}, $p) ! type-of(.) -> z:j(., '|'),
  function-annotations(%z:x('y') fn {}) ! (
    map:keys(.) ! local-name-from-QName(.),
    map:items(.)
  ) -> z:j(., '='),

  (: integrity constraints, QName literals, wildcard catch, finally :)
  for $f in (fn() { z:p(-1) }, fn() { error(#z:e) })
  return try {
    $f()
  } catch z:* {
    local-name-from-QName($err:code)
  } catch * {
    'rejected'
  } finally {}
)
