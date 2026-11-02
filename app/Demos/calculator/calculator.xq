(:~
 : Calculator: tokenizes, parses and evaluates arithmetic expressions.
 :
 : 4.0 features: enums, record and type declarations, map destructuring,
 : named regex groups, fn:op, fn:parse-integer, fn:divide-decimals.
 : @author Christian Gruen, BaseX
 :)
declare namespace calc = 'http://qt4cg.org/demos/calculator';

(:~ Token kinds. :)
declare type calc:kind as enum('number', 'name', 'operator', 'open', 'close');

(:~ Token with kind and string value. :)
declare record calc:token(
  kind   as calc:kind,
  value  as xs:string
);

(:~ Numeric literal. :)
declare record calc:num(
  value  as xs:decimal
);

(:~ Variable reference. :)
declare record calc:var(
  name  as xs:string
);

(:~ Unary minus. :)
declare record calc:negate(
  operand  as calc:expr
);

(:~ Binary operation. :)
declare record calc:binary(
  op     as xs:string,
  left   as calc:expr,
  right  as calc:expr
);

(:~ Syntax tree. :)
declare type calc:expr as (calc:num | calc:var | calc:negate | calc:binary);

(:~ Parsed subtree and position of the next token. :)
declare record calc:parsed(
  tree  as calc:expr,
  pos   as xs:integer
);

(:~ Binary operator. :)
declare record calc:operator(
  precedence  as xs:integer,
  apply       as fn(xs:decimal, xs:decimal) as xs:decimal,
  right       as xs:boolean := false()
);

(:~ Binary operators. :)
declare variable $calc:OPERATORS := {
  '+': calc:operator(1, op('+')),
  '-': calc:operator(1, op('-')),
  '*': calc:operator(2, op('*')),
  '/': calc:operator(2, op('div')),
  '%': calc:operator(2, fn($a, $b) { divide-decimals($a, $b)?remainder }),
  '^': calc:operator(3, fn($a, $b) { xs:decimal(math:pow($a, $b)) }, true())
};

(:~ Token pattern: the name of the matching group is the token kind. :)
declare variable $calc:TOKEN := '(?<number>0x[\da-fA-F]+|\d+(?:\.\d+)?)|(?<name>\p{L}+)|(?<open>\()|(?<close>\))|(?<operator>[-+*/%^])|\S';

(:~
 : Splits an expression into tokens.
 : @param  $input  expression string
 : @return tokens
 :)
declare function calc:tokenize(
  $input  as xs:string
) as calc:token* {
  for $segment in matching-segments($input, $calc:TOKEN)
  return calc:token(
    map:keys($segment?groups) otherwise error(
      #calc:syntax,
      `Unexpected character: { $segment?substring }`
    ),
    $segment?substring
  )
};

(:~
 : Parses an operand: a number, a variable, a negation or a parenthesized expression.
 : @param  $tokens  tokens
 : @param  $pos     position of the current token
 : @return parsed operand
 :)
declare function calc:operand(
  $tokens  as calc:token*,
  $pos     as xs:integer
) as calc:parsed {
  let $token := $tokens[$pos] otherwise error(#calc:syntax, 'Unexpected end of input')
  return switch ($token?kind) {
    case 'number' return (
      let $value := $token?value
      let $number := if (starts-with($value, '0x')) then (
        parse-integer(substring($value, 3), 16)
      ) else (
        xs:decimal($value)
      )
      return calc:parsed(calc:num($number), $pos + 1)
    )
    case 'name' return calc:parsed(calc:var($token?value), $pos + 1)
    case 'open' return (
      let $inner := calc:expression($tokens, $pos + 1, 1)
      return if ($tokens[$inner?pos]?kind = 'close') then (
        calc:parsed($inner?tree, $inner?pos + 1)
      ) else (
        error(#calc:syntax, 'Missing closing parenthesis')
      )
    )
    default return if ($token?value = '-') then (
      let $operand := calc:operand($tokens, $pos + 1)
      return calc:parsed(calc:negate($operand?tree), $operand?pos)
    ) else (
      error(#calc:syntax, `Unexpected token: { $token?value }`)
    )
  }
};

(:~
 : Parses an expression with operators of the given minimum precedence.
 : @param  $tokens  tokens
 : @param  $pos     position of the current token
 : @param  $min     minimum precedence
 : @return parsed expression
 :)
declare function calc:expression(
  $tokens  as calc:token*,
  $pos     as xs:integer,
  $min     as xs:integer
) as calc:parsed {
  calc:climb($tokens, calc:operand($tokens, $pos), $min)
};

(:~
 : Extends a left operand with operators of the given minimum precedence (precedence climbing).
 : @param  $tokens  tokens
 : @param  $left    parsed left operand
 : @param  $min     minimum precedence
 : @return parsed expression
 :)
declare function calc:climb(
  $tokens  as calc:token*,
  $left    as calc:parsed,
  $min     as xs:integer
) as calc:parsed {
  let $op := $tokens[$left?pos][?kind = 'operator']?value
  let $operator := $calc:OPERATORS?$op
  let $prec := $operator?precedence
  return if ($prec >= $min) then (
    let ${ $tree, $pos } := calc:expression($tokens, $left?pos + 1, if ($operator?right) then $prec else $prec + 1)
    return calc:climb($tokens, calc:parsed(calc:binary($op, $left?tree, $tree), $pos), $min)
  ) else (
    $left
  )
};

(:~
 : Parses an expression string.
 : @param  $input  expression string
 : @return syntax tree
 :)
declare function calc:parse(
  $input  as xs:string
) as calc:expr {
  let $tokens := calc:tokenize($input)
  let ${ $tree, $pos } := calc:expression($tokens, 1, 1)
  return if ($pos > count($tokens)) then (
    $tree
  ) else (
    error(#calc:syntax, `Unexpected token: { $tokens[$pos]?value }`)
  )
};

(:~
 : Evaluates a syntax tree.
 : @param  $tree  syntax tree
 : @param  $vars  variable bindings
 : @return result
 :)
declare function calc:evaluate(
  $tree  as calc:expr,
  $vars  as map(xs:string, xs:decimal)
) as xs:decimal {
  let $eval := calc:evaluate(?, $vars)
  return typeswitch ($tree) {
    case calc:num return $tree?value
    case calc:var return $vars?($tree?name) otherwise error(
      #calc:unknown,
      `Unknown variable: { $tree?name }`
    )
    case calc:negate return -$eval($tree?operand)
    default return $calc:OPERATORS?($tree?op)?apply($eval($tree?left), $eval($tree?right))
  }
};

(:~
 : Serializes a syntax tree in prefix notation.
 : @param  $tree  syntax tree
 : @return string
 :)
declare function calc:show(
  $tree  as calc:expr
) as xs:string {
  typeswitch ($tree) {
    case calc:num return string($tree?value)
    case calc:var return $tree?name
    case calc:negate return `(- { calc:show($tree?operand) })`
    default return `({ $tree?op } { calc:show($tree?left) } { calc:show($tree?right) })`
  }
};

let $vars := { 'x': 2, 'r': 2, 'pi': 3.14159 }
for $input in (
  '1 + 2 * 3',
  '(1 + 2) * 3',
  '2 ^ 3 ^ 2',
  '10 - 4 - 3',
  '-x + 10 / 4',
  'pi * r ^ 2',
  '0xFF % 7',
  '17.5 % 4',
  '1 / (x - 2)',
  'y + 1',
  '(1 + 2',
  '3 $ 4'
)
return try {
  let $tree := calc:parse($input)
  return `{ $input } ෴ { calc:show($tree) } = { calc:evaluate($tree, $vars) }`
} catch calc:* {
  `{ $input } ෴ { $err:description }`
} catch * {
  `{ $input } ෴ { local-name-from-QName($err:code) }`
}
