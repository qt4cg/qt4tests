(:~
 : Translates JMESPath expressions to XQuery 4.0 expressions that navigate JNodes.
 : Three modes are supported: "idiomatic" yields the code an XPath user would write,
 : "strict" yields code that preserves the semantics of JMESPath, and "mixed" combines
 : idiomatic navigation with the comparisons and conditions of the strict mode.
 :
 : @author Christian Gruen, BaseX
 :)
module namespace translate = 'http://www.w3.org/qt4cg/jmespath/translate';

(:~ Lexical tokens. :)
declare variable $translate:TOKENS := string-join((
  '"(?:[^"\\]|\\.)*"', "'(?:[^'\\]|\\.)*'", '`(?:[^`\\]|\\.)*`',
  '-?[0-9]+', '\[\]', '\[\?', '\|\|', '&amp;&amp;', '==', '!=', '<=', '>=',
  '[.*\[\],:@(){}|&amp;!<>]', '[A-Za-z_][A-Za-z0-9_]*', '\s+', '.'
), '|');

(:~ Binding powers of tokens. :)
declare variable $translate:BP := {
  '|': 1, '||': 2, '&amp;&amp;': 3, '==': 5, '!=': 5, '<': 5, '<=': 5, '>': 5, '>=': 5,
  '[]': 9, '*': 20, '[?': 21, '.': 40, '!': 45, '{': 50, '[': 55, '(': 60
};

(:~ Comparison operators. :)
declare variable $translate:COMPARISON := ('==', '!=', '<', '<=', '>', '>=');

(:~ Current node. :)
declare variable $translate:CURRENT := { 'type': 'current' };

(:~ Arities of the built-in functions (-1: variadic). :)
declare variable $translate:FUNCTIONS := {
  'abs': 1, 'avg': 1, 'ceil': 1, 'contains': 2, 'ends_with': 2, 'floor': 1, 'join': 2,
  'keys': 1, 'length': 1, 'map': 2, 'max': 1, 'max_by': 2, 'merge': -1, 'min': 1, 'min_by': 2,
  'not_null': -1, 'reverse': 1, 'sort': 1, 'sort_by': 2, 'starts_with': 2, 'sum': 1,
  'to_array': 1, 'to_number': 1, 'to_string': 1, 'type': 1, 'values': 1
};

(:~ Values that are false in JMESPath (members are compared with deep-equal). :)
declare variable $translate:FALSY := [ (), false(), "", [], {} ];

(:~ Pattern for strings that can be converted to numbers. :)
declare variable $translate:NUMBER := '^-?[0-9]+(\.[0-9]+)?([eE][+\-]?[0-9]+)?$';

(:~
 : Rejects an expression.
 : @param $reason reason
 : @return never
 :)
declare function translate:skip(
  $reason as xs:string
) {
  error(#translate:skip, $reason)
};

(: PARSER ===================================================================================== :)

(:~
 : Parses a JMESPath expression.
 : @param $expr JMESPath expression
 : @return syntax tree
 :)
declare function translate:parse(
  $expr as xs:string
) as map(*) {
  let $tokens := analyze-string($expr, $translate:TOKENS, 's')/fn:match/string()[
    not(matches(., '^\s+$'))
  ]
  let $result := translate:expression($tokens, 1, 0)
  return if ($result?pos <= count($tokens)) then translate:skip('trailing tokens') else $result?ast
};

(:~
 : Returns a parse result.
 : @param $ast syntax tree
 : @param $pos next position
 : @return result
 :)
declare function translate:result(
  $ast as map(*),
  $pos as xs:integer
) as map(*) {
  { 'ast': $ast, 'pos': $pos }
};

(:~
 : Returns the type of a token.
 : @param $tok token (can be empty)
 : @return type
 :)
declare function translate:type(
  $tok as xs:string?
) as xs:string {
  if (empty($tok)) then 'eof'
  else if (starts-with($tok, '"')) then 'quoted'
  else if (matches($tok, "^['`]")) then 'literal'
  else if (matches($tok, '^-?[0-9]')) then 'number'
  else if (matches($tok, '^[A-Za-z_]')) then 'name'
  else $tok
};

(:~
 : Returns the binding power of a token.
 : @param $tok token (can be empty)
 : @return binding power
 :)
declare function translate:bp(
  $tok as xs:string?
) as xs:integer {
  $translate:BP(translate:type($tok)) otherwise 0
};

(:~
 : Parses an expression (Pratt parser, modeled after jmespath.py).
 : @param $t tokens
 : @param $p current position
 : @param $bp binding power
 : @return expression and next position
 :)
declare function translate:expression(
  $t as xs:string*,
  $p as xs:integer,
  $bp as xs:integer
) as map(*) {
  let $nud := translate:nud($t, $p)
  return translate:leds($t, $nud?pos, $bp, $nud?ast)
};

(:~
 : Parses infix operators as long as they bind more tightly.
 : @param $t tokens
 : @param $p current position
 : @param $bp binding power
 : @param $left left operand
 : @return expression and next position
 :)
declare function translate:leds(
  $t as xs:string*,
  $p as xs:integer,
  $bp as xs:integer,
  $left as map(*)
) as map(*) {
  if ($bp < translate:bp($t[$p])) then (
    let $result := translate:led($t, $p + 1, $t[$p], $left)
    return translate:leds($t, $result?pos, $bp, $result?ast)
  ) else (
    translate:result($left, $p)
  )
};

(:~
 : Parses a prefix expression.
 : @param $t tokens
 : @param $p current position
 : @return expression and next position
 :)
declare function translate:nud(
  $t as xs:string*,
  $p as xs:integer
) as map(*) {
  let $tok := $t[$p]
  let $n := $p + 1
  return switch (translate:type($tok))
    case 'literal' return
      translate:result({ 'type': 'literal', 'value': translate:literal-value($tok) }, $n)
    case 'name' return
      translate:result({ 'type': 'field', 'name': $tok }, $n)
    case 'quoted' return
      if ($t[$n] = '(') then translate:skip('quoted function name')
      else translate:result({ 'type': 'field', 'name': parse-json($tok) }, $n)
    case '*' return
      let $right := if ($t[$n] = ']') then translate:result($translate:CURRENT, $n)
        else translate:rhs($t, $n, 20)
      return translate:result({
        'type': 'value_projection', 'left': $translate:CURRENT, 'right': $right?ast
      }, $right?pos)
    case '[?' return
      translate:filter($t, $n, $translate:CURRENT)
    case '{' return
      translate:hash($t, $n, [])
    case '(' return
      translate:expect($t, translate:expression($t, $n, 0), ')')
    case '[]' return
      let $right := translate:rhs($t, $n, 9)
      return translate:result({
        'type': 'projection', 'right': $right?ast,
        'left': { 'type': 'flatten', 'expr': $translate:CURRENT }
      }, $right?pos)
    case '!' return
      let $expr := translate:expression($t, $n, 45)
      return translate:result({ 'type': 'not', 'expr': $expr?ast }, $expr?pos)
    case '[' return
      if (translate:type($t[$n]) = ('number', ':')) then (
        translate:project-if-slice($t, $translate:CURRENT, translate:index($t, $n))
      ) else if ($t[$n] = '*' and $t[$n + 1] = ']') then (
        let $right := translate:rhs($t, $n + 2, 20)
        return translate:result({
          'type': 'projection', 'left': $translate:CURRENT, 'right': $right?ast
        }, $right?pos)
      ) else (
        translate:list($t, $n, [])
      )
    case '@' return
      translate:result($translate:CURRENT, $n)
    case '&amp;' return
      let $expr := translate:expression($t, $n, 0)
      return translate:result({ 'type': 'expref', 'expr': $expr?ast }, $expr?pos)
    default return
      translate:skip('token: ' || $tok)
};

(:~
 : Parses an infix expression.
 : @param $t tokens
 : @param $p position after the operator
 : @param $tok operator token
 : @param $left left operand
 : @return expression and next position
 :)
declare function translate:led(
  $t as xs:string*,
  $p as xs:integer,
  $tok as xs:string,
  $left as map(*)
) as map(*) {
  let $binary := fn($type, $bp) {
    let $right := translate:expression($t, $p, $bp)
    return translate:result({
      'type': $type, 'op': $tok, 'left': $left, 'right': $right?ast
    }, $right?pos)
  }
  return switch ($tok)
    case '.' return
      if ($t[$p] = '*') then (
        let $right := translate:rhs($t, $p + 1, 40)
        return translate:result({
          'type': 'value_projection', 'left': $left, 'right': $right?ast
        }, $right?pos)
      ) else (
        let $right := translate:dot-rhs($t, $p, 40)
        return translate:result(
          if ($left?type = 'subexpression') then (
            map:put($left, 'children', array:append($left?children, $right?ast))
          ) else {
            'type': 'subexpression', 'children': [ $left, $right?ast ]
          }, $right?pos)
      )
    case '|' return $binary('pipe', 1)
    case '||' return $binary('or', 2)
    case '&amp;&amp;' return $binary('and', 3)
    case '(' return
      if ($left?type = 'field') then translate:args($t, $p, $left?name, [])
      else translate:skip('function name')
    case '[?' return
      translate:filter($t, $p, $left)
    case '[]' return
      let $right := translate:rhs($t, $p, 9)
      return translate:result({
        'type': 'projection', 'right': $right?ast,
        'left': { 'type': 'flatten', 'expr': $left }
      }, $right?pos)
    case '[' return
      if (translate:type($t[$p]) = ('number', ':')) then (
        let $index := translate:index($t, $p)
        return if ($left?type = 'index_expression') then (
          translate:result(
            map:put($left, 'children', array:append($left?children, $index?ast)),
            $index?pos
          )
        ) else (
          translate:project-if-slice($t, $left, $index)
        )
      ) else if ($t[$p] = '*' and $t[$p + 1] = ']') then (
        let $right := translate:rhs($t, $p + 2, 20)
        return translate:result({
          'type': 'projection', 'left': $left, 'right': $right?ast
        }, $right?pos)
      ) else (
        translate:skip('bracket')
      )
    default return
      if ($tok = $translate:COMPARISON) then $binary('comparator', 5)
      else translate:skip('operator: ' || $tok)
};

(:~
 : Checks if the next token is the expected one and skips it.
 : @param $t tokens
 : @param $result parse result
 : @param $tok expected token
 : @return parse result
 :)
declare function translate:expect(
  $t as xs:string*,
  $result as map(*),
  $tok as xs:string
) as map(*) {
  if ($t[$result?pos] = $tok) then translate:result($result?ast, $result?pos + 1)
  else translate:skip('expected: ' || $tok)
};

(:~
 : Parses the right-hand side of a projection.
 : @param $t tokens
 : @param $p current position
 : @param $bp binding power
 : @return expression and next position
 :)
declare function translate:rhs(
  $t as xs:string*,
  $p as xs:integer,
  $bp as xs:integer
) as map(*) {
  let $tok := $t[$p]
  return if (translate:bp($tok) < 10) then translate:result($translate:CURRENT, $p)
    else if ($tok = ('[', '[?')) then translate:expression($t, $p, $bp)
    else if ($tok = '.') then translate:dot-rhs($t, $p + 1, $bp)
    else translate:skip('projection')
};

(:~
 : Parses the right-hand side of a dot.
 : @param $t tokens
 : @param $p current position
 : @param $bp binding power
 : @return expression and next position
 :)
declare function translate:dot-rhs(
  $t as xs:string*,
  $p as xs:integer,
  $bp as xs:integer
) as map(*) {
  let $tok := $t[$p]
  return if (translate:type($tok) = ('name', 'quoted', '*')) then translate:expression($t, $p, $bp)
    else if ($tok = '[') then translate:list($t, $p + 1, [])
    else if ($tok = '{') then translate:hash($t, $p + 1, [])
    else translate:skip('dot')
};

(:~
 : Parses a filter projection.
 : @param $t tokens
 : @param $p position after the opening bracket
 : @param $left left operand
 : @return expression and next position
 :)
declare function translate:filter(
  $t as xs:string*,
  $p as xs:integer,
  $left as map(*)
) as map(*) {
  let $cond := translate:expect($t, translate:expression($t, $p, 0), ']')
  let $right := if ($t[$cond?pos] = '[]') then translate:result($translate:CURRENT, $cond?pos)
    else translate:rhs($t, $cond?pos, 21)
  return translate:result({
    'type': 'filter_projection', 'left': $left, 'right': $right?ast, 'cond': $cond?ast
  }, $right?pos)
};

(:~
 : Parses an index or a slice.
 : @param $t tokens
 : @param $p position after the opening bracket
 : @return expression and next position
 :)
declare function translate:index(
  $t as xs:string*,
  $p as xs:integer
) as map(*) {
  if ($t[$p] = ':' or $t[$p + 1] = ':') then translate:slice($t, $p, [ (), (), () ], 1)
  else if ($t[$p + 1] = ']') then translate:result({ 'type': 'index', 'value': xs:integer($t[$p]) }, $p + 2)
  else translate:skip('index')
};

(:~
 : Parses a slice.
 : @param $t tokens
 : @param $p current position
 : @param $parts start, end and step
 : @param $i index of the current part
 : @return expression and next position
 :)
declare function translate:slice(
  $t as xs:string*,
  $p as xs:integer,
  $parts as array(*),
  $i as xs:integer
) as map(*) {
  let $tok := $t[$p]
  return if ($tok = ']') then (
    translate:result({
      'type': 'slice', 'start': $parts(1), 'end': $parts(2), 'step': $parts(3)
    }, $p + 1)
  ) else if ($tok = ':') then (
    if ($i = 3) then translate:skip('slice') else translate:slice($t, $p + 1, $parts, $i + 1)
  ) else if (translate:type($tok) = 'number') then (
    translate:slice($t, $p + 1, array:put($parts, $i, xs:integer($tok)), $i)
  ) else (
    translate:skip('slice')
  )
};

(:~
 : Creates an index expression, and a projection if the index is a slice.
 : @param $t tokens
 : @param $left left operand
 : @param $index index or slice and next position
 : @return expression and next position
 :)
declare function translate:project-if-slice(
  $t as xs:string*,
  $left as map(*),
  $index as map(*)
) as map(*) {
  let $expr := { 'type': 'index_expression', 'children': [ $left, $index?ast ] }
  return if ($index?ast?type = 'slice') then (
    let $right := translate:rhs($t, $index?pos, 20)
    return translate:result({ 'type': 'projection', 'left': $expr, 'right': $right?ast }, $right?pos)
  ) else (
    translate:result($expr, $index?pos)
  )
};

(:~
 : Parses a multi-select list.
 : @param $t tokens
 : @param $p current position
 : @param $items items parsed so far
 : @return expression and next position
 :)
declare function translate:list(
  $t as xs:string*,
  $p as xs:integer,
  $items as array(*)
) as map(*) {
  let $expr := translate:expression($t, $p, 0)
  let $items := array:append($items, $expr?ast)
  let $p := $expr?pos
  return if ($t[$p] = ']') then translate:result({ 'type': 'list', 'items': $items }, $p + 1)
    else if ($t[$p] = ',') then translate:list($t, $p + 1, $items)
    else translate:skip('list')
};

(:~
 : Parses a multi-select hash.
 : @param $t tokens
 : @param $p current position
 : @param $pairs key/value pairs parsed so far
 : @return expression and next position
 :)
declare function translate:hash(
  $t as xs:string*,
  $p as xs:integer,
  $pairs as array(*)
) as map(*) {
  let $key := switch (translate:type($t[$p]))
    case 'name' return $t[$p]
    case 'quoted' return parse-json($t[$p])
    default return translate:skip('key')
  return if (not($t[$p + 1] = ':')) then translate:skip('colon') else
  let $expr := translate:expression($t, $p + 2, 0)
  let $pairs := array:append($pairs, { 'key': $key, 'value': $expr?ast })
  let $p := $expr?pos
  return if ($t[$p] = ',') then translate:hash($t, $p + 1, $pairs)
    else if ($t[$p] = '}') then translate:result({ 'type': 'hash', 'pairs': $pairs }, $p + 1)
    else translate:skip('hash')
};

(:~
 : Parses function arguments.
 : @param $t tokens
 : @param $p current position
 : @param $name function name
 : @param $args arguments parsed so far
 : @return expression and next position
 :)
declare function translate:args(
  $t as xs:string*,
  $p as xs:integer,
  $name as xs:string,
  $args as array(*)
) as map(*) {
  if ($t[$p] = ')') then (
    translate:result({ 'type': 'function', 'name': $name, 'args': $args }, $p + 1)
  ) else if (empty($t[$p])) then (
    translate:skip('arguments')
  ) else (
    let $expr := translate:expression($t, $p, 0)
    let $next := if ($t[$expr?pos] = ',') then $expr?pos + 1 else $expr?pos
    return translate:args($t, $next, $name, array:append($args, $expr?ast))
  )
};

(:~
 : Returns the value of a literal token.
 : @param $tok token
 : @return value (empty for null)
 :)
declare function translate:literal-value(
  $tok as xs:string
) as item()? {
  let $content := substring($tok, 2, string-length($tok) - 2)
  return if (starts-with($tok, "'")) then (
    replace($content, "\'", "'", 'q')
  ) else (
    let $json := replace($content, '\`', '`', 'q')
    return try {
      parse-json($json)
    } catch * {
      (: legacy syntax: invalid JSON is parsed as string :)
      parse-json('"' || replace($json, '^\s+', '') || '"')
    }
  )
};

(: TRANSLATOR ================================================================================= :)

(:~
 : Translates a JMESPath expression.
 : @param $ast syntax tree
 : @param $mode mode ("idiomatic", "mixed", "strict")
 : @param $atomic atomic result expected
 : @param $input input
 : @return record with the code, the code of the projected nodes (if the result is a projection),
 :   or the code of the selected node (if the result is a path)
 :)
declare function translate:translate(
  $ast as map(*),
  $mode as xs:string,
  $atomic as xs:boolean := false(),
  $input as item()? := ()
) as map(*) {
  let $result := translate:code(translate:annotate($ast, [ $input ]), '$in', $mode)
  return switch () {
    case $result?multi return {
      'code': translate:value-code($result),
      'nodes': $result?code
    }
    case $atomic and empty($result?value) return {
      'code': `data({ translate:unwrap(translate:single($result)) })`,
      'node': $result?code
    }
    default return {
      'code': translate:value-code($result),
      'node': if (empty($result?value)) then $result?code else ()
    }
  }
};

(:~
 : Adds the known values and kinds of values to the expressions that are evaluated on known inputs.
 : @param $expr expression
 : @param $inputs inputs (the input, or the members of a projection)
 : @return annotated expression
 :)
declare function translate:annotate(
  $expr as map(*),
  $inputs as array(*)
) as map(*) {
  let $evaluable := translate:evaluable($expr)
  let $values := array:for-each($inputs, translate:known($expr, ?))
  let $kinds := fn($values) { distinct-values(array:for-each($values, translate:kind#1)?*) }
  let $known := map:merge((
    $expr,
    {
      'known': if (array:size($inputs) = 1) then $values?1 else (),
      'kinds': if ($evaluable) then $kinds($values) else (),
      'values': if ($evaluable) then $values else ()
    }
  ), { 'duplicates': 'use-last' })
  return switch ($expr?type)
    case 'function' return
      (: expression references are evaluated on the members of the array argument :)
      let $array := $expr?args?*[?type != 'expref'][1]
      let $members := if (exists($array)) then translate:members($array, $inputs, 'array(*)') else ()
      return map:put($known, 'args', array:for-each($expr?args, fn($arg) {
        if ($arg?type = 'expref') then (
          map:put($arg, 'expr', translate:annotate($arg?expr, $members otherwise []))
        ) else (
          translate:annotate($arg, $inputs)
        )
      }))
    case 'comparator' case 'and' case 'or' return
      map:put(map:put($known, 'left', translate:annotate($expr?left, $inputs)),
        'right', translate:annotate($expr?right, $inputs))
    case 'not' return
      map:put($known, 'expr', translate:annotate($expr?expr, $inputs))
    case 'pipe' return
      map:put($known, 'left', translate:annotate($expr?left, $inputs))
    case 'subexpression' case 'index_expression' return
      (: each step is evaluated on the values of the previous steps :)
      let $children := $expr?children?*
      return map:put($known, 'children', array {
        for $child at $c in $children
        let $values := fold-left(subsequence($children, 1, $c - 1), $inputs, fn($values, $previous) {
          if (translate:evaluable($previous)) then array:for-each($values, translate:known($previous, ?)) else []
        })
        return translate:annotate($child, $values)
      })
    case 'list' return
      map:put(map:put($known, 'context-kinds', $kinds($inputs)),
        'items', array:for-each($expr?items, translate:annotate(?, $inputs)))
    case 'hash' return
      map:put(map:put($known, 'context-kinds', $kinds($inputs)), 'pairs', array:for-each($expr?pairs,
        fn($pair) { map:put($pair, 'value', translate:annotate($pair?value, $inputs)) }))
    case 'flatten' return
      let $members := translate:members($expr?expr, $inputs, 'array(*)')
      return map:merge((
        $known,
        {
          'expr': translate:annotate($expr?expr, $inputs),
          'member-kinds': if (exists($members)) then $kinds($members) else (),
          'members-known': exists($members)
        }
      ), { 'duplicates': 'use-last' })
    case 'projection' case 'filter_projection' case 'value_projection' return
      let $type := if ($expr?type = 'value_projection') then 'map(*)' else 'array(*)'
      let $members := translate:members($expr?left, $inputs, $type) otherwise []
      let $annotated := map:put(map:put($known, 'left', translate:annotate($expr?left, $inputs)),
        'right', translate:annotate($expr?right, $members))
      return if (exists($expr?cond)) then (
        map:put($annotated, 'cond', translate:annotate($expr?cond, $members))
      ) else $annotated
    default return $known
};

(:~
 : Returns the members of the arrays or maps that an expression selects from known inputs.
 : @param $expr expression
 : @param $inputs inputs
 : @param $type type of the projected values (array(*) or map(*))
 : @return members, or an empty sequence if they are unknown
 :)
declare function translate:members(
  $expr as map(*),
  $inputs as array(*),
  $type as xs:string
) as array(*)? {
  (: projections: the code iterates over the results of the innermost projection :)
  if (translate:projected($expr)) then (
    if ($type = 'array(*)') then translate:leaves($expr, $inputs) else ()
  ) else if ($expr?type = 'function' and $expr?name = ('sort', 'sort_by', 'reverse')) then (
    (: reordered arrays: the same members, in a different order :)
    if ($type = 'array(*)') then translate:members($expr?args?*[1], $inputs, $type) else ()
  ) else if (translate:evaluable($expr)) then array:join(
    for member $input in $inputs
    let $value := translate:known($expr, $input)
    return switch () {
      case $type = 'array(*)' and $value instance of array(*) return $value
      case $type = 'map(*)' and $value instance of map(*) return
        array:build(map:keys($value), fn($key) { $value?($key) })
      default return []
    }
  )
};

(:~
 : Checks if an expression is a projection or flattening, which yields a sequence of JNodes.
 : @param $expr expression
 : @return result of check
 :)
declare function translate:projected(
  $expr as map(*)
) as xs:boolean {
  $expr?type = ('projection', 'filter_projection', 'value_projection', 'flatten')
};

(:~
 : Returns the results of a projection or flattening on known inputs; filters are ignored.
 : @param $expr expression
 : @param $inputs inputs
 : @return results, or an empty sequence if they are unknown
 :)
declare function translate:leaves(
  $expr as map(*),
  $inputs as array(*)
) as array(*)? {
  if ($expr?type = 'flatten') then (
    translate:members($expr?expr, $inputs, 'array(*)') ! array:join(
      for member $item in . return if ($item instance of array(*)) then $item else [ $item ]
    )
  ) else (
    let $type := if ($expr?type = 'value_projection') then 'map(*)' else 'array(*)'
    let $right := $expr?right
    let $items := translate:members($expr?left, $inputs, $type)
    let $projected := translate:projected($right)
    where exists($items) and ($projected or translate:evaluable($right))
    let $results := for member $item in $items return (
      if ($projected) then translate:leaves($right, [ $item ]) else [ translate:known($right, $item) ]
    )
    where count($results) = array:size($items)
    return array:join($results)
  )
};

(:~
 : Checks if the value of an expression can be computed from a known input.
 : @param $expr expression
 : @return result of check
 :)
declare function translate:evaluable(
  $expr as map(*)
) as xs:boolean {
  switch ($expr?type)
    case 'current' case 'field' case 'index' case 'literal' return true()
    case 'subexpression' case 'index_expression' return
      every $child in $expr?children?* satisfies translate:evaluable($child)
    case 'flatten' return translate:evaluable($expr?expr)
    case 'list' return every $item in $expr?items?* satisfies translate:evaluable($item)
    default return false()
};

(:~
 : Returns the JMESPath kind of a value.
 : @param $value value
 : @return kind
 :)
declare function translate:kind(
  $value as item()?
) as xs:string {
  typeswitch ($value)
    case empty-sequence() return 'null'
    case xs:string return 'string'
    case xs:numeric return 'number'
    case xs:boolean return 'boolean'
    case array(*) return 'array'
    default return 'object'
};

(:~
 : Returns the value that a path of fields and indexes selects from the input.
 : @param $expr expression
 : @param $input input
 : @return value, or an empty sequence if it is unknown or null
 :)
declare function translate:known(
  $expr as map(*),
  $input as item()?
) as item()? {
  switch ($expr?type)
    case 'current' return $input
    case 'literal' return $expr?value
    case 'field' return if ($input instance of map(*)) then $input?($expr?name) else ()
    case 'index' return if ($input instance of array(*)) then (
      let $size := array:size($input)
      let $pos := if ($expr?value >= 0) then $expr?value + 1 else $size + $expr?value + 1
      return if ($pos = 1 to $size) then $input?($pos) else ()
    ) else ()
    case 'subexpression' case 'index_expression' return
      fold-left($expr?children?*, $input, fn($value, $child) { translate:known($child, $value) })
    case 'flatten' return
      let $value := translate:known($expr?expr, $input)
      return if ($value instance of array(*)) then array:join(
        for member $m in $value return if ($m instance of array(*)) then $m else [ $m ]
      ) else ()
    case 'list' return if (exists($input)) then array:join($expr?items?* ! [ translate:known(., $input) ]) else ()
    default return ()
};

(:~
 : Appends a step to a base expression.
 : @param $base base expression
 : @param $step step
 : @param $slash use path operator (otherwise: simple map operator)
 : @return code
 :)
declare function translate:step(
  $base as xs:string,
  $step as xs:string,
  $slash as xs:boolean
) as xs:string {
  if ($base = '.') then $step
  else if ($step = '.' or $base = '()') then $base
  else $base || (if ($slash) then '/' else ' ! ') || $step
};

(:~
 : Returns a translation result.
 : @param $code code
 : @return record with the code, and a flag for a sequence of array members
 :)
declare function translate:rec(
  $code as xs:string
) as map(*) {
  { 'code': $code, 'multi': false() }
};

(:~
 : Returns a translation result for a computed value.
 : @param $value code that yields the value
 : @param $code code that yields the value as JNode (default: the value wrapped in a JTree)
 : @return translation result
 :)
declare function translate:wrap(
  $value as xs:string,
  $code as xs:string? := ()
) as map(*) {
  { 'code': $code otherwise `jtree({ $value })`, 'multi': false(), 'value': $value }
};

(:~
 : Removes parentheses that enclose a complete expression.
 : @param $code code
 : @return code
 :)
declare function translate:unwrap(
  $code as xs:string
) as xs:string {
  (: position of the parenthesis that closes the first character; string literals are skipped :)
  let $end := fold-left(
    characters($code),
    { 'depth': 0, 'quote': '', 'pos': 0, 'end': () },
    fn($s, $c) {
      if (exists($s?end) or ($s?pos = 0 and $c != '(')) then $s else
      let $pos := $s?pos + 1
      return switch () {
        case $s?quote != '' return
          { 'depth': $s?depth, 'quote': if ($c = $s?quote) then '' else $s?quote, 'pos': $pos, 'end': () }
        case $c = ('"', "'", '`') return { 'depth': $s?depth, 'quote': $c, 'pos': $pos, 'end': () }
        case $c = '(' return { 'depth': $s?depth + 1, 'quote': '', 'pos': $pos, 'end': () }
        case $c = ')' return
          { 'depth': $s?depth - 1, 'quote': '', 'pos': $pos, 'end': if ($s?depth = 1) then $pos else () }
        default return { 'depth': $s?depth, 'quote': '', 'pos': $pos, 'end': () }
      }
    }
  )?end
  return if ($end = string-length($code) and $code != '()') then (
    translate:unwrap(substring($code, 2, string-length($code) - 2))
  ) else (
    $code
  )
};

(:~
 : Restricts the JNodes of an expression to values of a type; a final name or index step is turned into a typed step.
 : @param $code code that yields JNodes
 : @param $type type of the values
 : @return code
 :)
declare function translate:guard(
  $code as xs:string,
  $type as xs:string
) as xs:string {
  let $step := '(^|/)([\i-[:]][\c-[:]]*|"([^"]|"")*"|[0-9]+)$'
  return if (matches($code, $step)) then (
    replace($code, $step, `$1jnode($2, { $type })`)
  ) else (
    translate:step($code, `self::jnode(*, { $type })`, true())
  )
};

(:~
 : Restricts the JNodes of a translation result to values of a type.
 : @param $result translation result
 : @param $type type of the values
 : @return code
 :)
declare function translate:guarded(
  $result as map(*),
  $type as xs:string
) as xs:string {
  (: known kinds: no type check, or no result :)
  let $kinds := if ($result?array) then 'array' else $result?kinds
  let $kind := { 'array(*)': 'array', 'map(*)': 'object' }($type)
  return switch () {
    case empty($kinds) or empty($kind) return translate:guard($result?code, $type)
    case every $k in $kinds satisfies $k = $kind return $result?code
    case not($kinds = $kind) return '()'
    default return translate:guard($result?code, $type)
  }
};

(:~
 : Returns a translation result for a value that is computed for each item of a base expression.
 : @param $base base expression
 : @param $value code that yields the value
 : @return translation result
 :)
declare function translate:mapped(
  $base as xs:string,
  $value as xs:string
) as map(*) {
  (: array constructors: no type check is needed for the resulting JNodes :)
  if ($base = '()') then map:put(translate:wrap('()', '()'), 'truth', false()) else map:put(translate:wrap(
    translate:step($base, $value, false()),
    translate:step($base, `jtree({ $value })`, false())
  ), 'array', starts-with($value, 'array {'))
};

(:~
 : Returns a translation result for a computed boolean value.
 : @param $type type of the value (xs:boolean or xs:boolean?)
 : @param $value code that yields the value
 : @param $code code that yields the value as JNode (default: the value wrapped in a JTree)
 : @return translation result
 :)
declare function translate:boolean(
  $type as xs:string,
  $value as xs:string,
  $code as xs:string? := ()
) as map(*) {
  map:put(translate:wrap($value, $code), 'type', $type)
};

(:~
 : Returns code that computes the JMESPath truthiness of a translation result.
 : @param $result translation result
 : @return code
 :)
declare function translate:truth(
  $result as map(*)
) as xs:string {
  switch () {
    case exists($result?truth) return translate:literal($result?truth)
    case exists($result?type) return $result?value
    default return translate:truthy($result, true()) otherwise translate:true(translate:value-code($result))
  }
};

(:~
 : Returns code that checks the JMESPath truthiness of a translation result with values of a single known kind.
 : @param $result translation result
 : @param $truthy check if the value is truthy (otherwise: falsy)
 : @return code, or an empty sequence if the kind is unknown
 :)
declare function translate:truthy(
  $result as map(*),
  $truthy as xs:boolean
) as xs:string? {
  let $kinds := $result?kinds
  where count($kinds) = 1
  let $value := translate:value-code($result)
  (: JNodes are atomized or coerced to their values, but have no effective boolean value :)
  let $coerced := if (translate:is-node($result)) then $result?code else $value
  return switch ($kinds) {
    case 'boolean' return if ($truthy) then $value else `not({ $value })`
    case 'number' return translate:literal($truthy)
    case 'null' return translate:literal(not($truthy))
    case 'string' return `{ $coerced } { if ($truthy) then '!=' else '=' } ""`
    case 'array' return `array:size({ $coerced }) { if ($truthy) then '>' else '=' } 0`
    default return `map:size({ $coerced }) { if ($truthy) then '>' else '=' } 0`
  }
};

(:~
 : Returns code that yields the value of a translation result.
 : @param $result translation result
 : @return code
 :)
declare function translate:value-code(
  $result as map(*)
) as xs:string {
  switch () {
    case exists($result?value) return $result?value
    (: computed values of projected JNodes: no JNodes are created :)
    case $result?multi return 'array { ' || ($result?items otherwise translate:step($result?code, 'jvalue()', false())) || ' }'
    default return translate:step($result?code, 'jvalue()', false())
  }
};

(:~
 : Returns code that yields a single JNode; sequences of array members are wrapped in an array.
 : @param $result translation result
 : @return code
 :)
declare function translate:single(
  $result as map(*)
) as xs:string {
  if ($result?multi) then (
    'jtree(array { ' || translate:step($result?code, 'jvalue()', false()) || ' })'
  ) else (
    $result?code
  )
};

(:~
 : Returns code that yields the value of an expression.
 : @param $expr expression
 : @param $c context code
 : @param $mode mode
 : @return code
 :)
declare function translate:value(
  $expr as map(*),
  $c as xs:string,
  $mode as xs:string
) as xs:string {
  translate:value-code(translate:code($expr, $c, $mode))
};

(:~
 : Translates an expression.
 : @param $expr expression
 : @param $c context code (yields zero or one JNode)
 : @param $mode mode
 : @return translation result
 :)
declare function translate:code(
  $expr as map(*),
  $c as xs:string,
  $mode as xs:string
) as map(*) {
  let $strict := $mode = 'strict'
  let $result := switch ($expr?type)
    case 'current' return
      translate:rec($c)
    (: fields and indexes: the context yields at most one JNode, so the path operator can be used :)
    case 'field' return
      translate:rec(translate:step($c, translate:name($expr?name, $c != '.'), true()))
    case 'literal' return
      let $value := $expr?value
      let $result := if (empty($value)) then translate:wrap('()', '()') else translate:wrap(translate:literal($value))
      (: the truthiness of a literal is known statically :)
      return map:put($result, 'truth', empty(array:index-of($translate:FALSY, $value)))
    case 'index' return
      let $i := $expr?value
      return translate:rec(if ($i >= 0) then (
        translate:step($c, if ($c != '.') then string($i + 1) else './' || $i + 1, true())
      ) else (
        translate:step(if ($strict) then translate:guard($c, 'array(*)') else $c,
          '*[last()' || (if ($i = -1) then '' else ' - ' || -$i - 1) || ']', true())
      ))
    case 'slice' return
      translate:slice-code($expr, $c, $mode)
    case 'subexpression' case 'index_expression' return
      translate:chain($expr?children?*, $c, $mode)
    case 'pipe' return
      translate:chain(($expr?left, $expr?right), $c, $mode)
    case 'projection' case 'value_projection' case 'filter_projection' return
      translate:projection($expr, $c, $mode)
    case 'flatten' return
      let $code := translate:code($expr?expr, $c, $mode)
      (: known members: arrays are flattened, other values are kept :)
      let $kinds := $expr?member-kinds
      let $member := switch () {
        case $expr?members-known and not($kinds = 'array') return '.'
        case exists($kinds) and (every $kind in $kinds satisfies $kind = 'array') return '*'
        default return '(if (self::jnode(*, array(*))) then * else .)'
      }
      return if ($strict and $member = '.') then (
        (: no nested arrays: the array is unchanged :)
        map:put(translate:rec(translate:guarded($code, 'array(*)')), 'array', true())
      ) else if ($strict) then (
        translate:mapped(translate:guarded($code, 'array(*)'),
          'array { ' || translate:step(translate:step('*', $member, false()), 'jvalue()', false()) || ' }')
      ) else if ($member = '.' and exists($code?members) and not($code?multi)) then (
        (: selected members without nested arrays: kept in their order :)
        { 'code': $code?members, 'multi': true(), 'members': $code?members }
      ) else {
        'code': translate:step(
          if ($code?multi) then $code?code else translate:step($code?code, '*', true()),
          $member, true()
        ),
        'multi': true()
      }
    case 'list' case 'hash' return
      let $list := $expr?type = 'list'
      let $exprs := if ($list) then $expr?items?* else $expr?pairs?*?value
      let $values := $exprs ! translate:value(., '.', $mode)
      let $value := if ($list) then (
        '[ ' || string-join($values, ', ') || ' ]'
      ) else (
        '{ ' || string-join(for $pair at $p in $expr?pairs?* return
          translate:string($pair?key) || ': ' || $values[$p], ', ') || ' }'
      )
      (: null context: no result; a context that is known to exist needs no check :)
      let $exists := exists($expr?context-kinds) and not($expr?context-kinds = 'null')
      let $check := $strict and not($exists)
      (: constant values need no context :)
      let $constant := $exists and (every $p in 1 to count($exprs) satisfies
        ($exprs[$p]?type = 'literal' or $values[$p] = '()'))
      let $code := fn($v) {
        if ($constant) then $v else
        translate:step($c, if ($check) then '(if (exists(jvalue())) then ' || $v || ' else ())'
          else $v, false())
      }
      return translate:wrap($code($value), $code('jtree(' || $value || ')'))
    case 'comparator' return
      let $operands := ($expr?left, $expr?right)
      let $results := $operands ! translate:code(., $c, $mode)
      let $l := translate:value-code($results[1])
      let $r := translate:value-code($results[2])
      (: comparison with null: existence check :)
      let $null := ($l, $r) = '()'
      let $other := if ($r = '()') then $l else $r
      (: comparison of a path with an atomic literal: values of the literal's type are compared :)
      let $typed := (
        let $literal := $operands[?type = 'literal' and ?value instance of xs:anyAtomicType]
        let $path := index-where($operands, fn { ?type != 'literal' })
        where count($literal) = 1 and count($path) = 1
        let $result := $results[$path]
        where translate:is-node($result)
        let $type := typeswitch ($literal?value)
          case xs:boolean return 'xs:boolean'
          case xs:string return 'xs:string'
          default return 'xs:numeric'
        return `{ translate:guard($result?code, $type) } = { translate:literal($literal?value) }`
      )
      (: idiomatic: two paths are compared as JNodes (a missing node differs from a null value) :)
      let $nodes := if ($mode = 'idiomatic' and
        (every $result in $results satisfies translate:is-node($result))) then (
        `deep-equal({ $results[1]?code }, { $results[2]?code })`
      ) else ()
      (: atomic values of the same known kind: general comparison :)
      let $atomic := if ((every $result in $results satisfies
        count($result?kinds) = 1 and $result?kinds = ('string', 'number', 'boolean')) and
        $results[1]?kinds = $results[2]?kinds) then (
        $results ! (if (translate:is-node(.)) then ?code else translate:value-code(.))
      ) else ()
      let $equal := ($typed, $nodes, `deep-equal({ $l }, { $r })`)[1]
      return switch ($expr?op)
        case '==' return translate:boolean('xs:boolean', switch () {
          case $null return `empty({ $other })`
          case exists($atomic) return string-join($atomic, ' = ')
          default return $equal
        })
        case '!=' return translate:boolean('xs:boolean', switch () {
          case $null return `exists({ $other })`
          case exists($atomic) return string-join($atomic, ' != ')
          default return `not({ $equal })`
        })
        default return
          let $known := $operands ! (if (?type = 'literal') then ?value else ?known)
          return switch () {
          (: known numbers: plain comparison :)
          case count($known[. instance of xs:numeric]) = 2 return
            translate:boolean('xs:boolean', string-join(for $result in $results return
              if (translate:is-node($result)) then $result?code else translate:value-code($result),
              ` { $expr?op } `))
          (: a known value other than a number: null :)
          case exists($known[not(. instance of xs:numeric)]) return
            map:put(translate:wrap('()', '()'), 'truth', false())
          default return
            (: two JNodes: typed by their values, atomized by the comparison :)
            let $nodes := every $result in $results satisfies translate:is-node($result)
            let $code := fn($v) {
              '(let $l := ' || (if ($nodes) then $results[1]?code else $l) ||
              ', $r := ' || (if ($nodes) then $results[2]?code else $r) || ' return ' ||
              'if (($l, $r) instance of ' || (if ($nodes) then 'jnode(*, xs:numeric)*' else 'xs:numeric*') ||
              ') then ' || $v || ' else ())'
            }
            let $value := '$l ' || $expr?op || ' $r'
            return translate:boolean('xs:boolean?', $code($value), $code('jtree(' || $value || ')'))
          }
    case 'or' case 'and' return
      let $type := $expr?type
      let $operands := (
        if ($type = 'or') then translate:or-operands($expr) else ($expr?left, $expr?right)
      ) ! translate:code(., $c, $mode)
      (: literals: in or chains, a truthy one ends the chain and falsy ones before the last operand are
         skipped; a literal first operand of and decides statically :)
      let $results := switch () {
        case $type = 'or' return
          let $kept := subsequence($operands, 1, index-where($operands, fn { ?truth = true() })[1])
          return $kept[position() = last() or not(?truth = false())]
        case exists($operands[1]?truth) return
          $operands[if ($operands[1]?truth) then 2 else 1]
        default return
          $operands
      }
      return switch () {
        case count($results) = 1 return
          $results
        case every $result in $results satisfies ($result?type = 'xs:boolean' or
          (empty($result?type) and $result?kinds = 'boolean' and count($result?kinds) = 1)) return
          (: booleans, or values that are known to be booleans: logical operator :)
          (: parentheses of nested operators are only kept for or operands of and :)
          let $operands := $results ! (
            let $code := translate:value-code(.)
            return if (exists(?logical) and not($type = 'and' and ?logical = 'or')) then translate:unwrap($code) else $code
          )
          let $value := string-join($operands, ` { $type } `)
          return map:put(translate:boolean('xs:boolean', `({ $value })`, `jtree({ $value })`), 'logical', $type)
        case $type = 'or' and (every $result in $results satisfies ($result?multi or $result?array)) return
          (: arrays: first non-empty one, or the last one :)
          (: identical operands: the operand itself :)
          let $values := distinct-values($results ! translate:value-code(.))
          let $value := string-join((
            $values[position() < last()] ! `{ . }[array:size(.) > 0]`, $values[last()]
          ), ' otherwise ')
          return map:put(translate:wrap(`({ $value })`, `jtree({ $value })`), 'array', true())
        case $type = 'or' and $mode = 'idiomatic' and
          (every $result in $results[position() < last()] satisfies translate:is-node($result)) return
          (: idiomatic: first existing operand; all but the last one must be paths :)
          translate:rec(`({ string-join($results ! translate:single(.), ' otherwise ') })`)
        case count($results) = 2 and exists($results?type) return
          (: a boolean operand: values instead of JNodes; a boolean first operand is the result
             if it decides; other first operands are reused, and bound to a variable unless they are plain :)
          let $l := $results[1]
          let $r := translate:value-code($results[2])
          let $bind := not($l?type = 'xs:boolean') and
            ($l?multi or not(translate:plain($l?value otherwise $l?code)))
          let $first := switch () {
            case not($bind) return $l
            case exists($l?type) return translate:boolean($l?type, '$v')
            default return translate:wrap('$v')
          }
          let $short := if ($l?type = 'xs:boolean') then translate:literal($type = 'or')
            else translate:value-code($first)
          let $if := `if ({ translate:unwrap(translate:truth($first)) })`
          let $value := if ($type = 'and') then `{ $if } then { $r } else { $short }`
            else `{ $if } then { $short } else { $r }`
          return translate:wrap(
            if ($bind) then `(let $v := { translate:value-code($l) } return { $value })` else `({ $value })`
          )
        case $type = 'or' return
          (: first truthy operand, or the last one; plain paths need no parentheses :)
          let $nodes := $results ! translate:single(.)
          let $candidates := $nodes[position() < last()]
          let $sequence := if (count($candidates) = 1 and translate:plain($candidates)) then (
            $candidates
          ) else (
            `({ string-join($candidates, ', ') })`
          )
          (: candidates of the same known kind: simpler truthiness check :)
          let $kinds := distinct-values($results[position() < last()] ! (if (count(?kinds) = 1) then ?kinds else ''))
          let $check := translate:truthy({ 'code': '.', 'kinds': $kinds[not($kinds = '')] }, true())
          (: candidates of different known kinds: a check for each candidate :)
          let $checks := $results[position() < last()] ! (
            if (count(?kinds) = 1) then translate:truthy({ 'code': '.', 'kinds': ?kinds }, true()) else ()
          )
          let $first := switch () {
            case exists($check) or count($checks) != count($candidates) or count($candidates) = 1 return
              let $found := translate:predicate($sequence, `[{ $check otherwise translate:true('jvalue()') }]`)
              return if (count($nodes) > 2) then `head({ $found })` else $found
            default return
              `({ string-join(for $node at $n in $candidates return translate:predicate($node, `[{ $checks[$n] }]`), ', ') })[1]`
          }
          return translate:rec(`({ $first } otherwise { $nodes[last()] })`)
        case $type = 'and' and translate:is-node($results[1]) and count($results[1]?kinds) = 1 and
          $results[1]?kinds != 'null' return
          (: first operand of a known kind, which exists: kept if falsy, otherwise the second operand :)
          let $falsy := translate:truthy({ 'code': '.', 'kinds': $results[1]?kinds }, false())
          return translate:rec(`({ translate:predicate($results[1]?code, `[{ $falsy }]`) } otherwise { translate:single($results[2]) })`)
        case $mode = 'idiomatic' and translate:is-node($results[1]) return
          (: idiomatic: second operand if the first exists :)
          translate:rec(`(if ({ translate:unwrap($results[1]?code) }) {{ { translate:single($results[2]) } }})`)
        default return
          (: second operand if the first is truthy; plain paths need no variable :)
          let $l := translate:single($results[1])
          let $r := translate:single($results[2])
          let $if := fn($a) {
            `if ({ translate:unwrap(translate:truth(map:put(translate:rec($a), 'kinds', $results[1]?kinds))) }) then { $r } else { $a }`
          }
          return translate:rec(
            if (translate:plain($l)) then `({ $if($l) })` else `(let $a := { $l } return { $if('$a') })`
          )
      }
    case 'not' return
      (: the negated code is kept, so a double negation yields the original condition :)
      let $result := translate:code($expr?expr, $c, $mode)
      let $value := switch () {
        case exists($result?negation) return $result?negation
        case exists($result?truth) return translate:literal(not($result?truth))
        case exists($result?type) return `not({ translate:unwrap($result?value) })`
        default return translate:truthy($result, false()) otherwise translate:false(translate:value-code($result))
      }
      let $negation := translate:truth($result)
      return map:put(translate:boolean('xs:boolean', $value), 'negation', $negation)
    case 'function' return
      translate:function($expr, $c, $mode)
    default return
      translate:skip('expression: ' || $expr?type)
  (: kinds of values that are known statically :)
  let $kinds := $expr?kinds
  return if (exists($kinds)) then (
    (: numbers are always truthy, null is falsy :)
    let $truth := switch () {
      case exists($result?truth) return $result?truth
      case every $kind in $kinds satisfies $kind = 'number' return true()
      case every $kind in $kinds satisfies $kind = 'null' return false()
      default return ()
    }
    return map:merge(($result, { 'kinds': $kinds, 'truth': $truth }), { 'duplicates': 'use-last' })
  ) else $result
};

(:~
 : Returns the operands of a chain of or expressions.
 : @param $expr expression
 : @return operands
 :)
declare function translate:or-operands(
  $expr as map(*)
) as map(*)+ {
  if ($expr?type = 'or') then (
    translate:or-operands($expr?left), translate:or-operands($expr?right)
  ) else (
    $expr
  )
};

(:~
 : Translates a chain of expressions (subexpression, index expression, pipe).
 : @param $exprs expressions
 : @param $c context code
 : @param $mode mode
 : @return translation result
 :)
declare function translate:chain(
  $exprs as map(*)+,
  $c as xs:string,
  $mode as xs:string
) as map(*) {
  let $result := translate:code(head($exprs), $c, $mode)
  return if (count($exprs) = 1) then $result
    else translate:chain(tail($exprs), translate:single($result), $mode)
};

(:~
 : Translates a projection.
 : @param $expr expression
 : @param $c context code
 : @param $mode mode
 : @return translation result
 :)
declare function translate:projection(
  $expr as map(*),
  $c as xs:string,
  $mode as xs:string
) as map(*) {
  let $type := $expr?type
  let $left := translate:code($expr?left, $c, $mode)
  let $right := translate:code($expr?right, '.', $mode)
  let $filter := if ($type = 'filter_projection') then (
    '[' || translate:unwrap(translate:bool($expr?cond, $mode)) || ']'
  ) else ''
  return if ($mode = 'strict') then (
    let $guard := if ($type = 'value_projection') then 'map(*)' else 'array(*)'
    let $value := translate:value-code($right)
    (: members with a type test: typed child step :)
    let $members := if ($filter = '' and starts-with($value, 'self::jnode(*, ')) then (
      substring-after($value, 'self::')
    ) else (
      translate:step('*' || $filter, $value, false())
    )
    let $slice := $left?slice
    return if (exists($slice) and $filter = '' and $type != 'value_projection' and $slice?items != '()') then (
      (: projected slice: members of the slice, without an intermediate array :)
      translate:mapped($slice?base, `array {{ { translate:step($slice?items, $value, false()) } }}`)
    ) else translate:mapped(translate:guarded($left, $guard),
      'array { ' || $members || ' }')
  ) else (
    (: selected members: the projection is applied with the simple map operator, which keeps their order :)
    let $ordered := exists($left?members) and $filter = '' and $type != 'value_projection'
    let $elems := switch () {
      case $left?multi and $type != 'value_projection' return $left?code
      case $ordered return $left?members
      default return translate:step(translate:single($left), '*', true())
    }
    return {
      'code': if (translate:is-path($expr?right, $mode) and not($ordered)) then (
        (: path: continue the steps from the projected elements :)
        translate:code($expr?right, translate:predicate($elems, $filter), $mode)?code
      ) else (
        translate:step(translate:predicate($elems, $filter), $right?code, false())
      ),
      'multi': true(),
      (: computed values: code without JNodes :)
      'items': $right?value ! translate:step(translate:predicate($elems, $filter), ., false())
    }
  )
};

(:~
 : Checks if a translation result selects a single JNode with a path.
 : @param $result translation result
 : @return result of check
 :)
declare function translate:is-node(
  $result as map(*)
) as xs:boolean {
  empty($result?value) and not($result?multi)
};

(:~
 : Checks if code is a plain path without whitespace and parentheses.
 : @param $code code
 : @return result of check
 :)
declare function translate:plain(
  $code as xs:string
) as xs:boolean {
  matches($code, '^[^\s()]+$')
};

(:~
 : Appends a predicate to an expression; a final selector step is parenthesized with its path.
 : @param $code code
 : @param $predicate predicate (can be empty)
 : @return code
 :)
declare function translate:predicate(
  $code as xs:string,
  $predicate as xs:string
) as xs:string {
  if ($predicate != '' and matches($code, '/(\d+|"([^"]|"")*"|\(\d[^()]*\))$')) then (
    `({ $code }){ $predicate }`
  ) else (
    $code || $predicate
  )
};

(:~
 : Returns a range of member positions for 0-based indexes.
 : @param $start start (optional)
 : @param $end end (optional)
 : @return range
 :)
declare function translate:range(
  $start as xs:integer?,
  $end as xs:integer?
) as xs:string {
  let $last := fn($n) { if ($n = 0) then 'last()' else `last() - { $n }` }
  return string-join((
    switch () {
      case empty($start) return '1'
      case $start >= 0 return string($start + 1)
      default return $last(-$start - 1)
    },
    switch () {
      case empty($end) return 'last()'
      case $end >= 0 return string($end)
      default return $last(-$end)
    }
  ), ' to ')
};

(:~
 : Returns a call of fn:slice that selects the members of a slice with a step other than 1.
 : @param $start start (optional)
 : @param $end end (optional)
 : @param $step step
 : @param $exact reject positions that may need to be clamped
 : @return code, "()" if the slice is always empty, or nothing if positions may need to be clamped
 :)
declare function translate:slice-call(
  $start as xs:integer?,
  $end as xs:integer?,
  $step as xs:integer,
  $exact as xs:boolean
) as xs:string? {
  (: 0-based positions and exclusive ends are converted to 1-based positions and inclusive ends :)
  let $s := $start ! (if (. >= 0) then . + 1 else .)
  let $e := switch () {
    case empty($end) return ()
    case $step > 0 return if ($end >= 0) then $end else $end - 1
    default return if ($end >= 0) then $end + 2 else $end + 1
  }
  (: positional arguments up to the first omitted one :)
  let $args := (
    $s ! string(.),
    $e ! (if (exists($s)) then string(.) else `end := { . }`),
    if (count(($s, $e)) = 2) then string($step) else `step := { $step }`
  )
  return switch () {
    case $e = 0 return '()'
    (: positions outside the array are clamped: starts before stepping, negative ends for negative steps :)
    case $exact and exists($start) and abs($step) > 1 and ($start < 0) = ($step > 0) return ()
    case $exact and $step < 0 and $end < -1 return ()
    default return `slice(*, { string-join($args, ', ') })`
  }
};

(:~
 : Translates a slice.
 : @param $expr expression
 : @param $c context code
 : @param $mode mode
 : @return translation result
 :)
declare function translate:slice-code(
  $expr as map(*),
  $c as xs:string,
  $mode as xs:string
) as map(*) {
  let ${ $start, $end, $step } := $expr
  let $k := $step otherwise 1
  return if ($k = 0) then translate:skip('slice step 0') else
  let $members := translate:slice-members($start, $end, $k)
  return if ($mode != 'strict' and $k = 1) then (
    let $s := $start otherwise 0
    return {
      'code': translate:step($c,
        if ($c != '.' and $s >= 0 and $end >= 0 and $end - $s <= 1000) then (
          (: small bounded slices: selector with a range of member positions :)
          `({ $s + 1 } to { $end })`
        ) else (
          $members
        ),
        true()),
      'multi': true()
    }
  ) else (
    (: a call of fn:slice, or positional predicates :)
    let $items := (if ($k = 1) then () else translate:slice-call($start, $end, $k, $mode != 'idiomatic')) otherwise $members
    let $base := translate:guard($c, 'array(*)')
    let $result := translate:mapped($base, if ($items = '()') then '[]' else `array {{ { $items } ! jvalue() }}`)
    (: selected members, in the order of the slice :)
    return map:merge(($result, {
      'members': if ($items = '()') then '()' else translate:step($base, $items, false()),
      'slice': { 'base': $base, 'items': $items }
    }), { 'duplicates': 'use-last' })
  )
};

(:~
 : Returns the members of a slice, selected by a range of positions and a step.
 : @param $start start (optional)
 : @param $end end (optional)
 : @param $step step other than 0
 : @return code
 :)
declare function translate:slice-members(
  $start as xs:integer?,
  $end as xs:integer?,
  $step as xs:integer
) as xs:string {
  (: negative steps: 0-based indexes from end (exclusive) to start (inclusive), in reverse order :)
  let $from := if ($step > 0) then $start else if (empty($end)) then () else $end + 1
  let $to := if ($step > 0) then $end else if (empty($start) or $start = -1) then () else $start + 1
  let $range := translate:range($from, $to)
  let $members := if ($range = '1 to last()') then '*' else `*[{ $range }]`
  let $ordered := if ($step > 0) then $members else `reverse({ $members })`
  return switch () {
    case $step < 0 and $end = -1 return '()'
    case abs($step) = 1 return $ordered
    default return `{ $ordered }[position() mod { abs($step) } = 1]`
  }
};

(:~
 : Translates a filter condition.
 : @param $expr expression
 : @param $mode mode
 : @return code
 :)
declare function translate:bool(
  $expr as map(*),
  $mode as xs:string
) as xs:string {
  if ($mode != 'idiomatic') then (
    translate:truth(translate:code($expr, '.', $mode))
  ) else switch ($expr?type)
    case 'comparator' return
      translate:operand($expr?left, $mode) || ' ' ||
      (if ($expr?op = '==') then '=' else $expr?op) || ' ' ||
      translate:operand($expr?right, $mode)
    case 'and' case 'or' return
      (: parentheses are only needed for or operands of and :)
      string-join(($expr?left, $expr?right) ! (
        let $code := translate:bool(., $mode)
        return if ($expr?type = 'and' and ?type = 'or') then `({ $code })` else $code
      ), ` { $expr?type } `)
    case 'not' return
      `not({ translate:unwrap(translate:bool($expr?expr, $mode)) })`
    default return
      if (translate:is-path($expr, $mode)) then translate:code($expr, '.', $mode)?code
      else translate:truth(translate:code($expr, '.', $mode))
};

(:~
 : Translates an operand of a comparison in a filter condition (idiomatic mode).
 : @param $expr expression
 : @param $mode mode
 : @return code
 :)
declare function translate:operand(
  $expr as map(*),
  $mode as xs:string
) as xs:string {
  if ($expr?type = 'literal') then translate:literal($expr?value)
  else if (translate:is-path($expr, $mode)) then translate:code($expr, '.', $mode)?code
  else '(' || translate:value($expr, '.', $mode) || ')'
};

(:~
 : Checks if an expression is translated to a pure path.
 : @param $expr expression
 : @param $mode mode
 : @return result of check
 :)
declare function translate:is-path(
  $expr as map(*),
  $mode as xs:string
) as xs:boolean {
  let $paths := $mode != 'strict'
  return switch ($expr?type)
    case 'current' case 'field' case 'index' return true()
    case 'subexpression' case 'index_expression' return
      every $child in $expr?children?* satisfies translate:is-path($child, $mode)
    case 'projection' case 'value_projection' case 'filter_projection' return
      $paths and translate:is-path($expr?left, $mode) and translate:is-path($expr?right, $mode)
    case 'flatten' return
      $paths and translate:is-path($expr?expr, $mode)
    case 'slice' return
      $paths and ($expr?step otherwise 1) = 1
    default return false()
};

(:~
 : Returns code that checks if a value is false in JMESPath: false, null, "", [] or {}.
 : @param $values code that yields zero or one value
 : @return code
 :)
declare function translate:false(
  $values as xs:string
) as xs:string {
  `exists(array:index-of({ translate:literal($translate:FALSY) }, { $values }))`
};

(:~
 : Returns code that computes the JMESPath truthiness of a value: false, null, "", [] and {} are false.
 : @param $values code that yields zero or one value
 : @return code
 :)
declare function translate:true(
  $values as xs:string
) as xs:string {
  `empty(array:index-of({ translate:literal($translate:FALSY) }, { $values }))`
};

(:~
 : Translates a function call.
 : @param $expr expression
 : @param $c context code
 : @param $mode mode
 : @return translation result
 :)
declare function translate:function(
  $expr as map(*),
  $c as xs:string,
  $mode as xs:string
) as map(*) {
  let $name := $expr?name
  let $arity := $translate:FUNCTIONS($name) otherwise translate:skip('function: ' || $name)
  let $args := $expr?args?* ! (
    if (?type = 'expref') then (
      let $result := translate:code(?expr, '.', $mode)
      return {
        'expref': translate:value-code($result),
        (: sort keys are atomized :)
        'key': $result?value otherwise translate:single($result)
      }
    ) else {
      let $result := translate:code(., $c, $mode)
      return {
        'node': translate:single($result),
        'value': translate:value-code($result),
        'atomic': $result?value otherwise translate:single($result),
        'members': $result?members, 'items': $result?items,
        'projected': if ($result?multi) then $result?code else ()
      }
    }
  )
  return if ($arity >= 0 and count($args) != $arity) then translate:skip('arity: ' || $name) else
  let $V := fn($i) { $args[$i]?value otherwise translate:skip('value expected: ' || $name) }
  let $N := fn($i) { $args[$i]?node otherwise translate:skip('value expected: ' || $name) }
  let $A := fn($i) { $args[$i]?atomic otherwise translate:skip('value expected: ' || $name) }
  let $M := fn($i) { $args[$i]?members otherwise translate:step($N($i), '*', true()) }
  (: atomized members: values or projected JNodes are used directly :)
  let $S := fn($i) { $args[$i]?items otherwise $args[$i]?projected otherwise $M($i) }
  let $I := fn($i) { $args[$i]?items otherwise translate:step($S($i), 'jvalue()', false()) }
  let $E := fn($i) { $args[$i]?expref otherwise translate:skip('expref expected: ' || $name) }
  let $K := fn($i) { $args[$i]?key otherwise translate:skip('expref expected: ' || $name) }
  (: JNodes are coerced to their values :)
  let $C := fn($i) { if ($expr?args?*[$i]?type = 'literal') then $V($i) else $N($i) }
  (: literal arguments and values of known inputs: the kinds of the values are known statically :)
  let $literal := $expr?args?*[1] ! (if (?type = 'literal') then ?value else ?known)
  let $kinds := $expr?args?*[1] ! (if (?type = 'literal') then translate:kind(?value) else ?kinds)
  let $kind := if (count($kinds) = 1) then $kinds else ()
  let $values := $expr?args?*[1] ! (if (?type = 'literal') then [ ?value ] else ?values)
  return switch ($name)
    case 'abs' return translate:wrap('abs(' || $A(1) || ')')
    case 'avg' case 'max' case 'min' return
      translate:wrap($name || '(' || $S(1) || ')', $name || '(' || $S(1) || ') ! jtree(.)')
    case 'ceil' return translate:wrap('ceiling(' || $A(1) || ')')
    case 'floor' return translate:wrap('floor(' || $A(1) || ')')
    case 'contains' return
      let $search := $expr?args?*[2][?type = 'literal']?value
      return translate:boolean('xs:boolean', switch () {
      case $kind = 'string' return `contains({ $C(1) }, { $A(2) })`
      (: atomic members of the same kind as the searched literal: general comparison :)
      case $literal instance of array(*) and $search instance of xs:anyAtomicType and
        (every $member in $literal?* satisfies translate:kind($member) = translate:kind($search)) return
        `{ $C(1) } = { $V(2) }`
      case $kind = 'array' return `exists(array:index-of({ $C(1) }, { $V(2) }))`
      default return `{ $N(1) } ! (if (self::jnode(*, xs:string)) then contains(., { $A(2) }) ` ||
        `else exists(array:index-of(., { $V(2) })))`
    })
    case 'ends_with' return translate:boolean('xs:boolean', 'ends-with(' || $A(1) || ', ' || $A(2) || ')')
    case 'starts_with' return translate:boolean('xs:boolean', 'starts-with(' || $A(1) || ', ' || $A(2) || ')')
    case 'join' return translate:wrap('string-join(' || $S(2) || ', ' || $A(1) || ')')
    case 'keys' return map:put(translate:wrap(`array {{ { $M(1) } ! jkey() }}`), 'items', $M(1) || ' ! jkey()')
    case 'length' return translate:wrap(switch () {
      case $kind = 'string' return `string-length({ $C(1) })`
      case $kind = 'array' return `array:size({ $C(1) })`
      case $kind = 'object' return `map:size({ $C(1) })`
      default return $N(1) || ' ! (if (self::jnode(*, xs:string)) then string-length(.) else count(*))'
    })
    case 'map' return translate:wrap('array:build(' || $M(2) || ', fn { ' || $E(1) || ' })')
    case 'max_by' case 'min_by' return translate:rec(
      (if ($name = 'max_by') then 'highest' else 'lowest') || '(' || $M(1) ||
      ', (), fn { ' || $K(2) || ' })[1]')
    case 'merge' return translate:wrap(
      if (count($args) = 1) then $V(1) else
      'map:merge((' || string-join((1 to count($args)) ! $V(.), ', ') || '), { "duplicates": "use-last" })')
    case 'not_null' return translate:rec(
      '(' || string-join((1 to count($args)) ! $N(.), ', ') || ')[exists(jvalue())][1]')
    case 'reverse' return translate:wrap(switch () {
      case $kind = 'string' return `string-join(reverse(characters({ $C(1) })))`
      case $kind = 'array' return `array:reverse({ $C(1) })`
      default return
        `{ $N(1) } ! (if (self::jnode(*, xs:string)) then string-join(reverse(characters(.))) ` ||
        `else array:reverse(.))`
    })
    case 'sort' return translate:wrap(`array {{ sort({ $I(1) }) }}`)
    case 'sort_by' return
      (: sorted JNodes, which are projected in their order :)
      let $sorted := 'sort(' || $M(1) || ', (), fn { ' || $K(2) || ' })'
      return map:put(translate:wrap(`array:of-members({ $sorted })`), 'members', $sorted)
    case 'sum' return translate:wrap('sum(' || $S(1) || ')')
    case 'to_array' return switch () {
      case $kind = 'array' return translate:wrap($V(1))
      case exists($kinds) and not($kinds = 'array') return translate:wrap(`[ { $V(1) } ]`)
      default return
        let $value := 'if ($v instance of array(*)) then $v else [ $v ]'
        let $let := '(let $v := ' || $V(1) || ' return '
        return translate:wrap($let || $value || ')', $let || 'jtree(' || $value || '))')
    }
    case 'to_number' return switch () {
      case $kind = 'number' return translate:wrap($V(1))
      case $kind = 'string' and exists($literal) return
        if (matches($literal, $translate:NUMBER)) then translate:wrap(`number({ $V(1) })`)
        else translate:wrap('()', '()')
      case exists($kinds) and not($kinds = ('number', 'string')) return translate:wrap('()', '()')
      (: strings that are numbers in JMESPath, or no numbers at all: conversion without NaN :)
      case exists($values) and (every $value in $values?*[. instance of xs:string] satisfies
        matches($value, $translate:NUMBER) or is-NaN(number($value))) return
        let $value := `number({ $C(1) })[not(is-NaN(.))]`
        return translate:wrap($value, $value || ' ! jtree(.)')
      default return
        let $number := `matches($v, "{ $translate:NUMBER }")`
        let $code := fn($wrap) {
          '(let $v := ' || $V(1) || ' return if ($v instance of xs:numeric) then ' || $wrap('$v') ||
          ' else if ($v instance of xs:string and ' || $number || ') then ' ||
          $wrap('number($v)') || ' else ())'
        }
        return translate:wrap($code(fn($v) { $v }), $code(fn($v) { 'jtree(' || $v || ')' }))
    }
    case 'to_string' return switch () {
      case $kind = 'string' return translate:wrap($V(1))
      case $kind = 'null' return translate:wrap('"null"')
      case exists($kinds) and not($kinds = ('string', 'null')) return
        translate:wrap(`serialize({ $C(1) }, {{ "method": "json" }})`)
      default return
        let $value := 'if ($v instance of xs:string) then $v ' ||
          'else if (empty($v)) then "null" else serialize($v, { "method": "json" })'
        let $let := '(let $v := ' || $V(1) || ' return '
        return translate:wrap($let || $value || ')', $let || 'jtree(' || $value || '))')
    }
    case 'type' return translate:wrap(
      (: known kind: name of the kind :)
      if (exists($kind)) then translate:string($kind) else
      'typeswitch (' || $V(1) || ') case empty-sequence() return "null" ' ||
      'case xs:string return "string" case xs:boolean return "boolean" ' ||
      'case xs:numeric return "number" case array(*) return "array" default return "object"')
    case 'values' return map:put(translate:wrap('array:of-members(' || $M(1) || ')'), 'members', $M(1))
    default return translate:skip('function: ' || $name)
};

(:~
 : Returns a name test.
 : @param $name name
 : @param $step single step after a slash
 : @return code
 :)
declare function translate:name(
  $name as xs:string,
  $step as xs:boolean
) as xs:string {
  switch () {
    case matches($name, '^[\i-[:]][\c-[:]]*$') return $name
    case $step return translate:string($name)
    default return './' || translate:string($name)
  }
};

(:~
 : Returns a string literal.
 : @param $string string
 : @return code
 :)
declare function translate:string(
  $string as xs:string
) as xs:string {
  if (matches($string, '[\p{Cc}-[\n\r\t&#x7F;-&#x9F;]]')) then translate:skip('control characters') else (),
  '"' || ($string => replace('&amp;', '&amp;amp;') => replace('"', '""')
    => replace('\r', '&amp;#xD;')) || '"'
};

(:~
 : Returns an XQuery expression for a JSON value.
 : @param $value value (empty for null)
 : @return code
 :)
declare function translate:literal(
  $value as item()?
) as xs:string {
  typeswitch ($value)
    case empty-sequence() return '()'
    case map(*) return
      if (map:empty($value)) then '{}' else
      '{ ' || string-join(map:for-each($value, fn($k, $v) {
        translate:string($k) || ': ' || translate:literal($v)
      }), ', ') || ' }'
    case array(*) return
      if (array:empty($value)) then '[]' else
      '[ ' || string-join(for member $m in $value return translate:literal($m), ', ') || ' ]'
    case xs:string return translate:string($value)
    case xs:double return
      if ($value = floor($value) and abs($value) < 1e15) then string(xs:integer($value))
      else if (contains(string($value), 'E')) then string($value)
      else string($value) || 'e0'
    case xs:boolean return $value || '()'
    default return translate:skip('literal: ' || $value)
};
