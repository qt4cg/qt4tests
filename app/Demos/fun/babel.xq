(:~
 : Babel: a calculator that parses itself with ixml and remembers its past.
 : invisible-xml, op(), function-lookup with fallbacks, apply with array:build,
 : lower-arity folds, labeled records, typeswitch on element unions,
 : QName literals, highest with a key, and fold-left as an interpreter loop.
 :)
declare namespace β = 'urn:babel';
declare namespace ixml = 'http://invisiblexml.org/NS';

declare record β:cell(v as xs:double, line as xs:string, why as xs:string? := ());

declare variable $β:PARSE := invisible-xml('
  expr: s, sum, s.
  -sum: prod; add.
  add: sum, s, @aop, s, prod.
  aop: "+"; "-".
  -prod: pow; mul.
  mul: prod, s, @mop, s, pow.
  mop: "×"; "÷"; "%".
  -pow: atom; exp.
  exp: atom, s, -"^", s, pow.
  -atom: num; ref; call; neg; -"(", s, sum, s, -")".
  neg: -"-", atom.
  ref: -"$", ["0"-"9"]+.
  num: ["0"-"9"]+, (".", ["0"-"9"]+)?.
  call: @name, -"(", s, sum ** (s, -",", s), s, -")".
  name: ["a"-"z"]+.
  -s: -" "*.
');

declare variable $β:OPS := {
  '+': op('+'),
  '-': op('-'),
  '×': op('*'),
  '÷': op('div'),
  '%': op('mod')
};

declare variable $β:LIB := {
  'hyp': fn($a as xs:double, $b as xs:double) { math:sqrt($a × $a + $b × $b) },
  'max': fn($a as xs:double, $b as xs:double) { max(($a, $b)) },
  'fib': fn($n as xs:double) {
    (1 to xs:integer($n)) => fold-left([ 0, 1 ], fn($p) { [ $p?2, $p?1 + $p?2 ] }) => array:get(1)
  }
};

declare function β:eval(
  $n   as node(),
  $env as xs:double*
) as xs:double {
  typeswitch ($n) {
    case document-node() return (
      if ($n/*/@ixml:state = 'failed') then (
        error(#β:syntax, 'no parse')
      ) else (
        β:eval($n/*, $env)
      )
    )
    case element(expr) return β:eval($n/*, $env)
    case element(num) return xs:double($n)
    case element(ref) return $env[xs:integer($n)] otherwise error(#β:time, `${ $n } lies in the future`)
    case element(neg) return -β:eval($n/*, $env)
    case element(exp) return math:pow(β:eval($n/*[1], $env), β:eval($n/*[2], $env))
    case element(add) | element(mul) return $β:OPS?($n/(@aop | @mop))(
      β:eval($n/*[1], $env),
      β:eval($n/*[2], $env)
    )
    case element(call) return (
      let $args := array:build($n/*, β:eval(?, $env))
      let $f := function-lookup(QName('http://www.w3.org/2005/xpath-functions/math', $n/@name), array:size($args))
        otherwise $β:LIB?($n/@name)[function-arity(.) = array:size($args)]
        otherwise error(#β:name, `{ $n/@name }#{ array:size($args) } is unknown`)
      return apply($f, $args)
    )
    default return error(#β:babel, name($n))
  }
};

let $cells := fold-left(
  (
    '1 + 2 × 3',
    '($1 - 4) ^ 2 ^ 2',
    'hyp(sqrt($2) - 6, $1 - 3)',
    'fib($3 × 2) % $1',
    'exp(log($4) × 2)',
    'max($1, $5 ÷ $3) ^ -1',
    '2 +× 3',
    'nope(1)',
    '$12 + 1'
  ),
  (),
  fn($env, $line) {
    $env, try {
      β:cell(round(β:eval($β:PARSE($line), $env?v), 9), $line)
    } catch * {
      β:cell(xs:double('NaN'), $line, `{ local-name-from-QName($err:code) }: { $err:description }`)
    }
  }
)
return (
  for $cell at $i in $cells
  return `${ $i } = { $cell?v } ⟵ { $cell?line }{ $cell?why ! ` ✗ { . }` }`,
  `peak: ${ highest(1 to count($cells), (), fn($i) { $cells[$i]?v[not(is-NaN(.))] }) }`,
  $β:PARSE('hyp(-$1, 2 ^ 3)')/*
)
