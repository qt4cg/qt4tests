(:~
 : Functions: every way to call a function, nested until it hurts.
 : Static, dynamic, partial and keyword calls; named references to built-in,
 : user-defined and constructor functions; focus functions; arrays and
 : maps as functions; partial-apply, apply, function-lookup, op; composition,
 : currying, a fixpoint combinator, method calls, memoization, and a parser
 : built from combinators whose semantics are swappable algebras: evaluation,
 : printing, compilation to closures and continuation passing.
 :)
declare namespace φ = 'urn:functions';

declare function φ:pair(
  $l as item()*,
  $r as item()* := ()
) as map(xs:string, item()*) {
  { 'l': $l, 'r': $r }
};

declare function φ:compose(
  $fs as fn(*)*
) as fn(item()*) as item()* {
  fold-left($fs, identity#1, fn($f, $g) { fn($x) { $g($f($x)) } })
};

declare function φ:curry(
  $f as fn(*)
) as fn(*) {
  if (function-arity($f) <= 1) then $f else (
    fn($x) { φ:curry(partial-apply($f, { 1: $x })) }
  )
};

declare function φ:twice(
  $f as fn(item()*) as item()*,
  $x as item()* := 1
) as item()* {
  $f($f($x))
};

declare function φ:fix(
  $f as fn(fn(*), item()*) as item()*
) as fn(item()*) as item()* {
  fn($x) { $f(φ:fix($f), $x) }
};

declare function φ:flip(
  $f as fn(item()*, item()*) as item()*
) as fn(item()*, item()*) as item()* {
  fn($a, $b) { $f($b, $a) }
};

declare function φ:memo(
  $f as fn(fn(xs:integer) as item()*, xs:integer) as item()*,
  $n as xs:integer
) as item()* {
  fold-left(0 to $n, {}, fn($memo, $i) {
    map:put($memo, $i, $f($memo, $i))
  })?$n
};

declare function φ:token(
  $regex as xs:string
) as fn(xs:string, xs:integer) as array(*)? {
  fn($s, $i) {
    analyze-string(substring($s, $i), `^\s*({ $regex })`)/*:match
    ! [ string(*:group), $i + string-length(.) ]
  }
};

declare function φ:seq(
  $parsers as fn(xs:string, xs:integer) as array(*)?*,
  $action  as fn(*)
) as fn(xs:string, xs:integer) as array(*)? {
  fn($s, $i) {
    fold-left($parsers, [ [], $i ], fn($acc, $p) {
      $acc ! $p($s, ?2) ! [ array:append($acc?1, ?1), ?2 ]
    }) ! [ apply($action, ?1), ?2 ]
  }
};

declare function φ:alt(
  $parsers as fn(xs:string, xs:integer) as array(*)?*
) as fn(xs:string, xs:integer) as array(*)? {
  fn($s, $i) {
    fold-left($parsers, (), fn($r, $p) { $r otherwise $p($s, $i) })
  }
};

declare function φ:many(
  $parser as fn(xs:string, xs:integer) as array(*)?
) as fn(xs:string, xs:integer) as array(*)? {
  fn($s, $i) {
    let $step := fn($state) {
      $parser($s, $state?2) ! [ array:append($state?1, ?1), ?2 ]
    }
    return while-do([ [], $i ], fn { exists($step(.)) }, $step)
  }
};

declare function φ:map(
  $parser as fn(xs:string, xs:integer) as array(*)?,
  $action as fn(item()*) as item()*
) as fn(xs:string, xs:integer) as array(*)? {
  fn($s, $i) { $parser($s, $i) ! [ $action(?1), ?2 ] }
};

declare function φ:lazy(
  $factory as fn(item()*) as fn(xs:string, xs:integer) as array(*)?,
  $arg     as item()*
) as fn(xs:string, xs:integer) as array(*)? {
  fn($s, $i) { $factory($arg)($s, $i) }
};

declare function φ:chain(
  $operand   as fn(xs:string, xs:integer) as array(*)?,
  $operators as xs:string,
  $algebra   as map(xs:string, fn(*))
) as fn(xs:string, xs:integer) as array(*)? {
  φ:seq(
    ($operand, φ:many(φ:seq((φ:token($operators), $operand), fn($o, $v) { [ $o, $v ] }))),
    fn($first, $rest) {
      fold-left($rest?*, $first, fn($acc, $pair) {
        $algebra =?> op(replace($pair?1, '/', 'div'), $acc, $pair?2)
      })
    }
  )
};

declare function φ:expr(
  $algebra as map(xs:string, fn(*))
) as fn(xs:string, xs:integer) as array(*)? {
  φ:chain(φ:chain(φ:factor($algebra), '[*/]', $algebra), '[+\-]', $algebra)
};

declare function φ:factor(
  $algebra as map(xs:string, fn(*))
) as fn(xs:string, xs:integer) as array(*)? {
  φ:alt((
    φ:map(φ:token('\d+'), $algebra?num(?, ?) => partial-apply({ 1: $algebra })),
    φ:map(φ:token('[a-z]+'), fn($name) { $algebra =?> var($name) }),
    φ:seq((φ:token('\('), φ:lazy(φ:expr#1, $algebra), φ:token('\)')), fn($l, $e, $r) { $e })
  ))
};

declare variable $φ:EVAL := {
  'num': fn($self, $n) { xs:integer($n) },
  'var': fn($self, $name) { error(#φ:unbound, $name) },
  'op': fn($self, $o, $a, $b) { op($o)($a, $b) }
};

declare variable $φ:SHOW := {
  'num': fn($self, $n) { $n },
  'var': fn($self, $name) { $name },
  'op': fn($self, $o, $a, $b) { `({ $o } { $a } { $b })` }
};

declare variable $φ:COMPILE := {
  'num': fn($self, $n) { $φ:EVAL?num($self, $n) => φ:const() },
  'var': fn($self, $name) { fn($env) { $env?$name } },
  'op': fn($self, $o, $a, $b) { fn($env) { $φ:EVAL =?> op($o, $a($env), $b($env)) } }
};

declare variable $φ:CPS := {
  'num': fn($self, $n) { fn($k) { $k(xs:integer($n)) } },
  'var': $φ:EVAL?var,
  'op': fn($self, $o, $a, $b) {
    fn($k) { $a(fn($x) { $b(fn($y) { $k(op($o)($x, $y)) }) }) }
  }
};

declare function φ:const(
  $value as item()*
) as fn(item()*) as item()* {
  fn($ignored) { $value }
};

declare function φ:run(
  $algebra as map(xs:string, fn(*)),
  $input   as xs:string
) as item()* {
  let $result := φ:expr($algebra)($input, 1)
  return if ($result?2 = string-length($input) + 1) then $result?1 else '✗'
};

declare function φ:j(
  $items as item()*
) as xs:string {
  string-join($items, ' ')
};

(
  (: currying built-in and user-defined functions :)
  φ:j((
    φ:curry(substring#3)('functional')(2)(3),
    φ:curry(φ:pair#2)('l')('r')?r,
    φ:curry(φ:curry#1)(concat(?, ?, ?))('x')('q')('4')
  )),

  (: composition of references, partial applications and focus functions :)
  φ:compose((
    upper-case#1,
    characters#1,
    reverse#1,
    string-join(?, '.'),
    concat(?, '!'),
    fn { `‹{ . }›` }
  ))('xquery'),

  (: a fixpoint, applied twice :)
  φ:twice(
    φ:fix(fn($self, $n) { if ($n <= 1) then 1 else $n × $self($n - 1) }),
    3
  ),

  (: arrays and maps as functions :)
  φ:j((
    for-each(2 to 4, [ 'a', 'b', 'c', 'd' ]),
    filter(('x', 'y', 'z'), { 'x': true(), 'y': false(), 'z': true() }),
    sort(('b', 'a', 'c'), (), { 'a': 3, 'b': 1, 'c': 2 })
  )),

  (: lookups, apply, operators, pairs :)
  φ:j((
    apply(function-lookup(#math:pow, 2), [ 2, 10 ]),
    fold-right(1 to 4, 0, op('-')),
    for-each-pair(
      (abs#1, op('-')(0, ?), round(?, 1)),
      (-2, 3, 1.25),
      fn($f, $x) { $f($x) }
    ),
    highest(('apple', 'fig', 'banana'), (), string-length#1)
  )),

  (: keyword arguments with placeholders, higher-order arrows :)
  φ:j((
    format-integer(?, picture := 'I')(42),
    op('otherwise')(φ:pair('l')?r, 'R'),
    (6 => (fn($n) { fn($m) { $n × $m } })())(7),
    ('3', 'x') ! (try { xs:integer#1(.) } catch * { '✗' })
  )),

  (: names and arities of all kinds of function items :)
  (abs#1, φ:compose#1, fn { . }, φ:pair#2, xs:integer#1, [], {}, op('+'))
  ! `{ function-name(.) ! local-name-from-QName(.) otherwise '∅' }/{ function-arity(.) }`
  => φ:j(),

  (: a method that calls itself :)
  {
    'n': 5,
    'down': fn($m) {
      if ($m?n = 0) then 'liftoff' else ($m?n, map:put($m, 'n', $m?n - 1) =?> down())
    }
  } =?> down() => φ:j(),

  (: mutual recursion between methods, memoization through a map coerced to a function :)
  let $parity := {
    'even': fn($m, $n) { $n = 0 or $m =?> odd($n - 1) },
    'odd': fn($m, $n) { $n != 0 and $m =?> even($n - 1) }
  }
  return φ:j((
    (7, 10) ! ($parity =?> even(.)),
    φ:memo(fn($fib, $i) { if ($i < 2) then $i else $fib($i - 1) + $fib($i - 2) }, 50)
  )),

  (: functions from names, flipped and partially applied by position :)
  φ:j((
    φ:compose(
      ('characters', 'reverse', 'string-join')
      ! function-lookup(QName('http://www.w3.org/2005/xpath-functions', .), 1)
    )('stressed'),
    partial-apply(φ:flip(op('-')), { 2: 100 })(1),
    φ:twice(φ:curry(φ:twice#2), op('+')(?, 1))(0),
    sort-with(
      ('bb', 'a', 'ccc', 'dd'),
      (fn($a, $b) { compare(string-length($a), string-length($b)) }, φ:flip(compare#2))
    )
  )),

  (: keywords for user functions, arrows to dynamic and partial targets :)
  let $shout := φ:compose((upper-case#1, concat(?, '!')))
  return φ:j((
    φ:pair(r := 'R', l := 'L') => map:items() => string-join(),
    'hey' => $shout(),
    (1, 2, 3) =!> (op('*')(?, 10))(),
    for-each(('a', 'b'), φ:curry(φ:flip(concat#2))('-'))
  )),

  (: a parser built from nothing but function items, with interchangeable semantics :)
  φ:j(
    ('2 * (3 + 4) - 5', '((1 + 2) * (3 + 4)) / 7', '10 - 4 - 3', '1 +')
    ! φ:run($φ:EVAL, .)
  ),
  φ:run($φ:SHOW, '(x + 1) * (x - 1) / y'),
  let $compiled := φ:run($φ:COMPILE, '(x + 1) * (x - 1) / y')
  let $continued := φ:run($φ:CPS, '2 * (3 + 4) - 5')
  return φ:j((
    ({ 'x': 5, 'y': 3 }, { 'x': 3, 'y': 4 }) ! $compiled(.),
    $continued(identity#1),
    $continued(φ:twice(op('*')(?, 2), ?)),
    $continued(fn($r) { $compiled({ 'x': $r, 'y': $r - 1 }) })
  ))
)
