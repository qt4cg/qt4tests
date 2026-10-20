(:~
 : Translates JSONPath queries (RFC 9535) to XQuery 4.0 expressions that navigate JNodes.
 : Three modes are supported: "idiomatic" yields the code an XPath user would write,
 : "strict" yields code that preserves the semantics of JSONPath, and "mixed" combines
 : idiomatic navigation with the comparisons of the strict mode.
 :
 : @author Christian Gruen, BaseX
 :)
module namespace translate = 'http://www.w3.org/qt4cg/jsonpath/translate';

(:~ Lexical tokens. :)
declare variable $translate:TOKENS := string-join((
  '"(?:[^"\\]|\\.)*"', "'(?:[^'\\]|\\.)*'",
  '-?[0-9]+(?:\.[0-9]+)?(?:[eE][+\-]?[0-9]+)?',
  '\.\.', '==|!=|<=|>=|\|\||&amp;&amp;', '[$@.\[\],:?()!<>*]',
  '[A-Za-z_\P{IsBasicLatin}][A-Za-z0-9_\P{IsBasicLatin}]*',
  '\s+', '.'
), '|');

(:~ Comparison operators. :)
declare variable $translate:COMPARISON := ('==', '!=', '<', '<=', '>', '>=');

(:~
 : Rejects a query.
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
 : Parses a JSONPath query.
 : @param $path JSONPath query
 : @return syntax tree
 :)
declare function translate:parse(
  $path as xs:string
) as map(*) {
  let $tokens := analyze-string($path, $translate:TOKENS, 's')/fn:match/string()[
    not(matches(., '^\s+$'))
  ]
  let $result := translate:query($tokens, 1)
  return if ($result?pos <= count($tokens)) then translate:skip('trailing tokens') else $result?ast
};

(:~
 : Parses a query.
 : @param $t tokens
 : @param $p current position
 : @return syntax tree and next position
 :)
declare function translate:query(
  $t as xs:string*,
  $p as xs:integer
) as map(*) {
  if (not($t[$p] = ('$', '@'))) then translate:skip('query') else (),
  let $segs := translate:segments($t, $p + 1, [])
  return {
    'ast': { 'type': 'query', 'root': $t[$p], 'segs': $segs?ast },
    'pos': $segs?pos
  }
};

(:~
 : Parses segments.
 : @param $t tokens
 : @param $p current position
 : @param $segs segments parsed so far
 : @return segments and next position
 :)
declare function translate:segments(
  $t as xs:string*,
  $p as xs:integer,
  $segs as array(*)
) as map(*) {
  let $tok := $t[$p]
  return if ($tok = ('.', '..', '[')) then (
    let $next := $t[$p + 1]
    let $result := if ($tok = '[') then (
      translate:bracket($t, $p + 1, [])
    ) else if ($tok = '..' and $next = '[') then (
      translate:bracket($t, $p + 2, [])
    ) else if ($next = '*') then (
      { 'ast': [ { 'type': 'wildcard' } ], 'pos': $p + 2 }
    ) else if (translate:is-name($next)) then (
      { 'ast': [ { 'type': 'name', 'value': $next } ], 'pos': $p + 2 }
    ) else (
      translate:skip('segment')
    )
    return translate:segments($t, $result?pos,
      array:append($segs, { 'desc': $tok = '..', 'sels': $result?ast }))
  ) else (
    { 'ast': $segs, 'pos': $p }
  )
};

(:~
 : Parses the selectors of a bracketed selection.
 : @param $t tokens
 : @param $p current position
 : @param $sels selectors parsed so far
 : @return selectors and next position
 :)
declare function translate:bracket(
  $t as xs:string*,
  $p as xs:integer,
  $sels as array(*)
) as map(*) {
  let $result := translate:selector($t, $p)
  let $sels := array:append($sels, $result?ast)
  let $p := $result?pos
  return if ($t[$p] = ',') then translate:bracket($t, $p + 1, $sels)
    else if ($t[$p] = ']') then { 'ast': $sels, 'pos': $p + 1 }
    else translate:skip('bracket')
};

(:~
 : Parses a selector.
 : @param $t tokens
 : @param $p current position
 : @return selector and next position
 :)
declare function translate:selector(
  $t as xs:string*,
  $p as xs:integer
) as map(*) {
  let $tok := $t[$p]
  return if (translate:is-string($tok)) then (
    { 'ast': { 'type': 'name', 'value': translate:unescape($tok) }, 'pos': $p + 1 }
  ) else if ($tok = '*') then (
    { 'ast': { 'type': 'wildcard' }, 'pos': $p + 1 }
  ) else if ($tok = '?') then (
    let $result := translate:or($t, $p + 1)
    return { 'ast': { 'type': 'filter', 'expr': $result?ast }, 'pos': $result?pos }
  ) else if (translate:is-int($tok) or $tok = ':') then (
    let $start := if (translate:is-int($tok)) then xs:integer($tok) else ()
    let $p := if (exists($start)) then $p + 1 else $p
    return if (not($t[$p] = ':')) then (
      { 'ast': { 'type': 'index', 'value': $start }, 'pos': $p }
    ) else (
      let $end := if (translate:is-int($t[$p + 1])) then xs:integer($t[$p + 1]) else ()
      let $p := if (exists($end)) then $p + 2 else $p + 1
      let $step := if ($t[$p] = ':' and translate:is-int($t[$p + 1])) then xs:integer($t[$p + 1])
        else ()
      let $p := if ($t[$p] = ':') then (if (exists($step)) then $p + 2 else $p + 1) else $p
      return {
        'ast': { 'type': 'slice', 'start': $start, 'end': $end, 'step': $step },
        'pos': $p
      }
    )
  ) else (
    translate:skip('selector')
  )
};

(:~
 : Parses a logical OR expression.
 : @param $t tokens
 : @param $p current position
 : @return expression and next position
 :)
declare function translate:or(
  $t as xs:string*,
  $p as xs:integer
) as map(*) {
  translate:logical($t, $p, '||', 'or', translate:and#2)
};

(:~
 : Parses a logical AND expression.
 : @param $t tokens
 : @param $p current position
 : @return expression and next position
 :)
declare function translate:and(
  $t as xs:string*,
  $p as xs:integer
) as map(*) {
  translate:logical($t, $p, '&amp;&amp;', 'and', translate:basic#2)
};

(:~
 : Parses a logical expression with operands.
 : @param $t tokens
 : @param $p current position
 : @param $op operator token
 : @param $type type of the expression
 : @param $operand function for parsing operands
 : @return expression and next position
 :)
declare function translate:logical(
  $t as xs:string*,
  $p as xs:integer,
  $op as xs:string,
  $type as xs:string,
  $operand as fn(xs:string*, xs:integer) as map(*)
) as map(*) {
  let $first := $operand($t, $p)
  let $result := translate:logical-rest($t, $first?pos, $op, $operand, [ $first?ast ])
  return if (array:size($result?ast) = 1) then $first else {
    'ast': { 'type': $type, 'ops': $result?ast }, 'pos': $result?pos
  }
};

(:~
 : Parses the remaining operands of a logical expression.
 : @param $t tokens
 : @param $p current position
 : @param $op operator token
 : @param $operand function for parsing operands
 : @param $ops operands parsed so far
 : @return operands and next position
 :)
declare function translate:logical-rest(
  $t as xs:string*,
  $p as xs:integer,
  $op as xs:string,
  $operand as fn(xs:string*, xs:integer) as map(*),
  $ops as array(*)
) as map(*) {
  if ($t[$p] = $op) then (
    let $result := $operand($t, $p + 1)
    return translate:logical-rest($t, $result?pos, $op, $operand, array:append($ops, $result?ast))
  ) else (
    { 'ast': $ops, 'pos': $p }
  )
};

(:~
 : Parses a basic expression (parenthesized, negated, comparison, test).
 : @param $t tokens
 : @param $p current position
 : @return expression and next position
 :)
declare function translate:basic(
  $t as xs:string*,
  $p as xs:integer
) as map(*) {
  if ($t[$p] = '!') then (
    let $result := translate:basic($t, $p + 1)
    return if ($result?ast?type = 'cmp' and $t[$p + 1] != '(') then (
      translate:skip('negated comparison')
    ) else {
      'ast': { 'type': 'not', 'expr': $result?ast }, 'pos': $result?pos
    }
  ) else if ($t[$p] = '(') then (
    let $result := translate:or($t, $p + 1)
    return if ($t[$result?pos] = ')') then (
      { 'ast': $result?ast, 'pos': $result?pos + 1 }
    ) else (
      translate:skip('parenthesis')
    )
  ) else (
    let $left := translate:primary($t, $p)
    let $op := $t[$left?pos]
    return if ($op = $translate:COMPARISON) then (
      let $right := translate:primary($t, $left?pos + 1)
      return {
        'ast': { 'type': 'cmp', 'op': $op, 'left': $left?ast, 'right': $right?ast },
        'pos': $right?pos
      }
    ) else if ($left?ast?type = ('query', 'function')) then (
      { 'ast': { 'type': 'test', 'expr': $left?ast }, 'pos': $left?pos }
    ) else (
      translate:skip('literal as test')
    )
  )
};

(:~
 : Parses a primary expression (query, literal, function call).
 : @param $t tokens
 : @param $p current position
 : @return expression and next position
 :)
declare function translate:primary(
  $t as xs:string*,
  $p as xs:integer
) as map(*) {
  let $tok := $t[$p]
  return if ($tok = ('$', '@')) then (
    translate:query($t, $p)
  ) else if (translate:is-string($tok)) then (
    { 'ast': { 'type': 'string', 'value': translate:unescape($tok) }, 'pos': $p + 1 }
  ) else if (matches($tok, '^-?[0-9]')) then (
    { 'ast': { 'type': 'number', 'value': $tok }, 'pos': $p + 1 }
  ) else if ($tok = ('true', 'false')) then (
    { 'ast': { 'type': 'boolean', 'value': $tok = 'true' }, 'pos': $p + 1 }
  ) else if ($tok = 'null') then (
    { 'ast': { 'type': 'null' }, 'pos': $p + 1 }
  ) else if (matches($tok, '^[a-z][a-z0-9_]*$') and $t[$p + 1] = '(') then (
    let $args := if ($t[$p + 2] = ')') then { 'ast': [], 'pos': $p + 3 }
      else translate:args($t, $p + 2, [])
    return {
      'ast': { 'type': 'function', 'name': $tok, 'args': $args?ast },
      'pos': $args?pos
    }
  ) else (
    translate:skip('primary')
  )
};

(:~
 : Parses function arguments.
 : @param $t tokens
 : @param $p current position
 : @param $args arguments parsed so far
 : @return arguments and next position
 :)
declare function translate:args(
  $t as xs:string*,
  $p as xs:integer,
  $args as array(*)
) as map(*) {
  (: literals, queries and function calls are passed on as values :)
  let $primary := try { translate:primary($t, $p) } catch translate:skip { () }
  let $result := if ($t[$primary?pos] = (',', ')')) then $primary else translate:or($t, $p)
  let $arg := $result?ast
  let $args := array:append($args, $arg)
  let $p := $result?pos
  return if ($t[$p] = ',') then translate:args($t, $p + 1, $args)
    else if ($t[$p] = ')') then { 'ast': $args, 'pos': $p + 1 }
    else translate:skip('arguments')
};

(:~
 : Checks if a token is a string literal.
 : @param $tok token (can be empty)
 : @return result of check
 :)
declare function translate:is-string(
  $tok as xs:string?
) as xs:boolean {
  matches($tok, '^["'']')
};

(:~
 : Checks if a token is an integer.
 : @param $tok token (can be empty)
 : @return result of check
 :)
declare function translate:is-int(
  $tok as xs:string?
) as xs:boolean {
  matches($tok, '^-?(0|[1-9][0-9]*)$') and $tok != '-0'
};

(:~
 : Checks if a token is a member name shorthand.
 : @param $tok token (can be empty)
 : @return result of check
 :)
declare function translate:is-name(
  $tok as xs:string?
) as xs:boolean {
  matches($tok, '^[A-Za-z_\P{IsBasicLatin}][A-Za-z0-9_\P{IsBasicLatin}]*$')
};

(:~
 : Returns the value of a string literal.
 : @param $tok token
 : @return string
 :)
declare function translate:unescape(
  $tok as xs:string
) as xs:string {
  let $content := substring($tok, 2, string-length($tok) - 2)
  let $json := string-join(analyze-string($content, '\\.|"|[^\\"]+', 's')/fn:match ! (
    if (. = "\'" and starts-with($tok, "'")) then "'" else if (. = '"') then '\"' else string()
  ))
  return parse-json('"' || $json || '"')
};

(: TRANSLATOR ================================================================================= :)

(:~
 : Translates a JSONPath query.
 : @param $ast syntax tree
 : @param $mode mode ("idiomatic", "mixed", "strict")
 : @param $input input
 : @return code
 :)
declare function translate:translate(
  $ast as map(*),
  $mode as xs:string,
  $input as item()? := ()
) as xs:string {
  translate:query-code(translate:annotate($ast, [ $input ], $input), $mode)
};

(:~
 : Adds the kinds of the selected values to the queries that are evaluated on known inputs.
 : @param $expr expression
 : @param $inputs inputs (the input, or the candidates of a filter)
 : @param $root input of absolute queries
 : @return annotated expression
 :)
declare function translate:annotate(
  $expr as map(*),
  $inputs as array(*),
  $root as item()?
) as map(*) {
  let $annotate := translate:annotate(?, $inputs, $root)
  return switch ($expr?type)
    case 'query' return
      let $start := if ($expr?root = '$') then [ $root ] else $inputs
      let $segs := $expr?segs?*
      (: filters: candidates are the children of the nodes selected by the previous segments :)
      let $annotated := for $seg at $s in $segs
        let $nodes := translate:selected(subsequence($segs, 1, $s - 1), $start)
        let $candidates := translate:children(
          if ($seg?desc) then translate:descendants($nodes) else $nodes, { 'type': 'wildcard' })
        return map:put($seg, 'sels', array:for-each($seg?sels, fn($sel) {
          if ($sel?type = 'filter') then map:put($sel, 'expr', translate:annotate($sel?expr, $candidates, $root))
          else $sel
        }))
      (: singular queries: one value for each input, if all inputs have one :)
      let $singular := every $seg in $segs satisfies (
        not($seg?desc) and count($seg?sels?*) = 1 and $seg?sels?*?type = ('name', 'index')
      )
      let $present := $singular and array:size($start) > 0 and (
        every $i in 1 to array:size($start) satisfies
          array:size(translate:selected($segs, [ $start?($i) ])) = 1
      )
      return map:merge((
        $expr,
        {
          'segs': array { $annotated },
          'kinds': distinct-values(array:for-each(translate:selected($segs, $start), translate:kind#1)?*),
          'present': $present
        }
      ), { 'duplicates': 'use-last' })
    case 'or' case 'and' return map:put($expr, 'ops', array:for-each($expr?ops, $annotate))
    case 'not' case 'test' return map:put($expr, 'expr', $annotate($expr?expr))
    case 'cmp' return map:put(map:put($expr, 'left', $annotate($expr?left)), 'right', $annotate($expr?right))
    case 'function' return map:put($expr, 'args', array:for-each($expr?args, $annotate))
    default return $expr
};

(:~
 : Returns the values selected by segments; filters and slices select all children.
 : @param $segs segments
 : @param $inputs inputs
 : @return selected values
 :)
declare function translate:selected(
  $segs as map(*)*,
  $inputs as array(*)
) as array(*) {
  fold-left($segs, $inputs, fn($values, $seg) {
    let $nodes := if ($seg?desc) then translate:descendants($values) else $values
    return array:join($seg?sels?* ! translate:children($nodes, .))
  })
};

(:~
 : Returns the children of values that are selected by a selector.
 : @param $values values
 : @param $sel selector
 : @return children
 :)
declare function translate:children(
  $values as array(*),
  $sel as map(*)
) as array(*) {
  array:join(
    for member $value in $values
    return switch () {
      case $sel?type = 'name' return
        if ($value instance of map(*) and map:contains($value, $sel?value)) then [ $value?($sel?value) ] else []
      case $sel?type = 'index' return if ($value instance of array(*)) then (
        let $size := array:size($value)
        let $pos := if ($sel?value >= 0) then $sel?value + 1 else $size + $sel?value + 1
        return if ($pos = 1 to $size) then [ $value?($pos) ] else []
      ) else []
      case $value instance of array(*) return $value
      case $value instance of map(*) return array:build(map:keys($value), fn($key) { $value?($key) })
      default return []
    }
  )
};

(:~
 : Returns values and their descendants.
 : @param $values values
 : @return values and descendants
 :)
declare function translate:descendants(
  $values as array(*)
) as array(*) {
  array:join(
    for member $value in $values
    return array:join(([ $value ], translate:descendants(translate:children([ $value ], { 'type': 'wildcard' }))))
  )
};

(:~
 : Returns the JSON kind of a value.
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
 : Translates a query.
 : @param $query query
 : @param $mode mode
 : @param $type required type of the selected values (optional)
 : @return code
 :)
declare function translate:query-code(
  $query as map(*),
  $mode as xs:string,
  $type as xs:string? := ()
) as xs:string {
  let $strict := $mode = 'strict'
  let $segs := $query?segs?*
  (: type test in the last step if it selects a single name :)
  let $typed := exists($type) and deep-equal($segs[last()]?sels?*?type, 'name')
  (: strict mode: the path operator keeps the order of the selected nodes as long as all segments
     select children with a single selector; descendants, several selectors and negative slice
     steps require the simple map operator :)
  let $simple := fn($s) {
    not($s?desc) and count($s?sels?*) = 1 and not(($s?sels?*?step otherwise 1) < 0)
  }
  let $code := fold-left($segs, if ($query?root = '$') then '$in' else '', fn($code, $seg, $pos) {
    let $path := not($strict) or (every $s in $segs[position() <= $pos] satisfies $simple($s))
    let $slash := $path and ($seg?desc or $code != '')
    let $keys := every $s in $seg?sels?* satisfies (
      $s?type = 'name' or ($s?type = 'index' and $s?value >= 0)
    )
    let $sels := if ($typed and $pos = count($segs)) then (
      `jnode({ translate:selector-code($seg?sels?*, $mode, true()) }, { $type })`
    ) else if ($slash and $keys and count($seg?sels?*) > 1) then (
      (: names and indexes after a slash: selector with a sequence of keys :)
      $seg?sels?* ! (if (?type = 'name') then translate:string(?value) else string(?value + 1))
    ) else (
      let $n := count($seg?sels?*)
      return $seg?sels?* ! translate:selector-code(., $mode, $slash and $n = 1, $slash and $n > 1)
    )
    let $sel := if (count($sels) = 1) then $sels else '(' || string-join($sels, ', ') || ')'
    return if ($seg?desc) then (
      if ($strict) then string-join(($code[. != ''], 'descendant-or-self::jnode()', $sel), ' ! ')
      else ($code[. != ''] otherwise '.') || '//' || $sel
    ) else (
      string-join(($code[. != ''], $sel), if ($path) then '/' else ' ! ')
    )
  })
  let $self := `self::jnode(*, { $type })`
  return switch () {
    case empty($type) or $typed return $code[. != ''] otherwise '.'
    case $code = '' return $self
    default return $code || (if ($strict and not(every $s in $segs satisfies $simple($s))) then ' ! '
      else '/') || $self
  }
};

(:~
 : Translates a selector.
 : @param $sel selector
 : @param $mode mode
 : @param $step single step after a slash
 : @param $nav navigational step (one of several selectors after a slash)
 : @return code
 :)
declare function translate:selector-code(
  $sel as map(*),
  $mode as xs:string,
  $step as xs:boolean,
  $nav as xs:boolean := false()
) as xs:string {
  let $strict := $mode = 'strict'
  (: key selection: selector after a slash, navigational kind test, or selector path :)
  let $key := fn($key) {
    switch () {
      case $step return $key
      case $nav return `jnode({ $key })`
      default return `./{ $key }`
    }
  }
  return switch ($sel?type)
    case 'name' return if (translate:ncname($sel?value)) then $sel?value
      else $key(translate:string($sel?value))
    case 'wildcard' return '*'
    case 'index' return
      let $i := $sel?value
      return if ($i >= 0) then (
        $key(string($i + 1))
      ) else (
        (if ($strict) then 'self::jnode(*, array(*))/' else '') ||
        '*[last()' || (if ($i = -1) then '' else ' - ' || -$i - 1) || ']'
      )
    case 'slice' return translate:slice($sel, $mode, $step)
    case 'filter' return '*[' || translate:expr($sel?expr, $mode) || ']'
    default return translate:skip('selector: ' || $sel?type)
};

(:~
 : Checks if a key can be written as a name step.
 : @param $key key
 : @return result of check
 :)
declare function translate:ncname(
  $key as xs:string
) as xs:boolean {
  matches($key, '^[\i-[:]][\c-[:]]*$')
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
 : Translates a slice selector.
 : @param $sel selector
 : @param $mode mode
 : @param $single single step after a slash
 : @return code
 :)
declare function translate:slice(
  $sel as map(*),
  $mode as xs:string,
  $single as xs:boolean
) as xs:string {
  let ${ $start, $end, $step } := $sel
  let $k := $step otherwise 1
  let $s := $start otherwise 0
  (: fn:slice is called with a simple map operator; after a slash, it would be a selector :)
  let $call := if ($k = (0, 1) or ($mode != 'strict' and $k > 0)) then ()
    else translate:slice-call($start, $end, $k, $mode != 'idiomatic')
  return if ($single and $k = 1 and $s >= 0 and $end >= 0 and $end - $s <= 1000) then (
    (: small bounded slices: selector with a range of member positions :)
    `({ $s + 1 } to { $end })`
  ) else if ($k = 0 or $call = '()') then (
    '()'
  ) else if (exists($call)) then (
    (: other steps: call of fn:slice on arrays :)
    'self::jnode(*, array(*)) ! ' || $call
  ) else (
    (: positional predicates, restricted to arrays in strict mode; reversed members need the simple map operator :)
    let $guard := switch () {
      case $k < 0 return 'self::jnode(*, array(*)) ! '
      case $mode = 'strict' return 'self::jnode(*, array(*))/'
      default return ''
    }
    return $guard || translate:slice-members($start, $end, $k)
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
 : Translates a logical expression.
 : @param $expr expression
 : @param $mode mode
 : @return code
 :)
declare function translate:expr(
  $expr as map(*),
  $mode as xs:string
) as xs:string {
  switch ($expr?type)
    case 'or' return string-join($expr?ops?* ! translate:expr(., $mode), ' or ')
    case 'and' return string-join($expr?ops?* ! (
      let $code := translate:expr(., $mode)
      return if (?type = 'or') then '(' || $code || ')' else $code
    ), ' and ')
    case 'not' return 'not(' || translate:expr($expr?expr, $mode) || ')'
    case 'test' return
      let $e := $expr?expr
      return if ($e?type = 'query') then (
        let $code := translate:query-code($e, $mode)
        return if ($mode = 'strict') then 'exists(' || $code || ')' else $code
      ) else if ($e?name = ('match', 'search')) then (
        translate:operand($e, $mode)?value
      ) else (
        translate:skip('function as test: ' || $e?name)
      )
    case 'cmp' return translate:comparison($expr, $mode)
    default return translate:skip('expression: ' || $expr?type)
};

(:~
 : Translates a comparison.
 : @param $expr expression
 : @param $mode mode
 : @return code
 :)
declare function translate:comparison(
  $expr as map(*),
  $mode as xs:string
) as xs:string {
  let $l := translate:operand($expr?left, $mode)
  let $r := translate:operand($expr?right, $mode)
  let $literal := ('string', 'number', 'boolean', 'null')
  return if ($l?nothing or $r?nothing) then (
    (: an operand that yields nothing: equal only to nothing, unordered :)
    let $other := if ($l?nothing) then ($r, $expr?right) else ($l, $expr?left)
    let $equal := switch () {
      case $other[1]?nothing return true()
      case $other[2]?type = $literal return false()
      default return ()
    }
    return switch ($expr?op) {
      case '<' case '>' return 'false()'
      case '!=' return if (exists($equal)) then `{ not($equal) }()` else `exists({ $other[1]?node })`
      default return if (exists($equal)) then `{ $equal }()` else `empty({ $other[1]?node })`
    }
  ) else if ($mode = 'idiomatic') then (
    $l?idiom || ' ' || (if ($expr?op = '==') then '=' else $expr?op) || ' ' || $r?idiom
  ) else if ($expr?left?type = 'query' and $expr?right?type = $literal) then (
    translate:typed($expr?left, $mode, $expr?op, $expr?right, $r?value)
  ) else if ($expr?right?type = 'query' and $expr?left?type = $literal) then (
    let $op := { '<': '>', '>': '<', '<=': '>=', '>=': '<=' }($expr?op) otherwise $expr?op
    return translate:typed($expr?right, $mode, $op, $expr?left, $l?value)
  ) else switch ($expr?op)
    case '==' return translate:equal($l, $r)
    case '!=' return 'not(' || translate:equal($l, $r) || ')'
    case '<' return translate:less($l, $r)
    case '>' return translate:less($r, $l)
    case '<=' return '(' || translate:less($l, $r) || ' or ' || translate:equal($l, $r) || ')'
    case '>=' return '(' || translate:less($r, $l) || ' or ' || translate:equal($l, $r) || ')'
    default return translate:skip('operator: ' || $expr?op)
};

(:~
 : Returns code for comparing a query with a literal: only values of the literal's type are compared.
 : @param $query query
 : @param $mode mode
 : @param $op operator
 : @param $literal literal
 : @param $value code of the literal
 : @return code
 :)
declare function translate:typed(
  $query as map(*),
  $mode as xs:string,
  $op as xs:string,
  $literal as map(*),
  $value as xs:string
) as xs:string {
  (: null and booleans are unordered: < and > never match, <= and >= are equality checks :)
  let $ordered := $literal?type = ('number', 'string')
  let $op := if ($ordered) then $op else if ($op = ('<', '>')) then '' else
    if ($op = ('<=', '>=')) then '==' else $op
  let $type := {
    'number': 'xs:numeric', 'string': 'xs:string', 'boolean': 'xs:boolean', 'null': 'empty-sequence()'
  }($literal?type)
  let $nodes := translate:query-code($query, $mode, $type)
  let $equal := if ($literal?type = 'null') then (
    $nodes
  ) else (
    `{ $nodes } { if ($op = ('==', '!=')) then '=' else $op } { $value }`
  )
  return switch ($op) {
    case '' return 'false()'
    case '!=' return `not({ $equal })`
    default return $equal
  }
};

(:~
 : Returns code for an equality comparison.
 : @param $l left operand
 : @param $r right operand
 : @return code
 :)
declare function translate:equal(
  $l as map(*),
  $r as map(*)
) as xs:string {
  (: operands as JNodes: values are compared, nothing only equals nothing, null differs from nothing :)
  `deep-equal({ $l?node }, { $r?node })`
};

(:~
 : Returns code for an ordering comparison.
 : @param $l left operand
 : @param $r right operand
 : @return code
 :)
declare function translate:less(
  $l as map(*),
  $r as map(*)
) as xs:string {
  '(some $l in ' || $l?value || ', $r in ' || $r?value || ' satisfies ' ||
  '(($l, $r) instance of xs:numeric+ or ($l, $r) instance of xs:string+) and $l lt $r)'
};

(:~
 : Translates a comparable operand or function argument.
 : @param $expr expression
 : @param $mode mode
 : @return record with the code of the value, the code of the JNode, and the idiomatic code
 :)
declare function translate:operand(
  $expr as map(*),
  $mode as xs:string
) as map(*) {
  switch ($expr?type)
    case 'query' return
      let $code := translate:query-code($expr, $mode)
      return { 'value': $code || ' ! jvalue()', 'node': $code, 'idiom': $code, 'query': $code }
    case 'string' return
      let $code := translate:string($expr?value)
      return { 'value': $code, 'node': `jtree({ $code })`, 'idiom': $code }
    case 'number' return
      (: fractions as doubles, as decimals are compared exactly :)
      let $lex := $expr?value
      let $value := if (contains($lex, '.') and not(matches($lex, '[eE]'))) then $lex || 'e0' else $lex
      return { 'value': $value, 'node': `jtree({ $value })`, 'idiom': $lex }
    case 'boolean' return
      let $code := $expr?value || '()'
      return { 'value': $code, 'node': `jtree({ $code })`, 'idiom': $code }
    case 'null' return { 'value': '()', 'node': 'jtree(())', 'idiom': '()' }
    case 'function' return translate:function($expr, $mode)
    default return translate:skip('operand: ' || $expr?type)
};

(:~
 : Translates a function call.
 : @param $expr expression
 : @param $mode mode
 : @return record with the code of the value, the code of the JNode, and the idiomatic code
 :)
declare function translate:function(
  $expr as map(*),
  $mode as xs:string
) as map(*) {
  let $args := $expr?args?* ! translate:operand(., $mode)
  let $name := $expr?name
  let $arity := (
    { 'length': 1, 'count': 1, 'value': 1, 'match': 2, 'search': 2 }($name)
    otherwise translate:skip('function: ' || $name)
  )
  return if (count($args) != $arity) then translate:skip('arity: ' || $name) else
  switch ($name)
    case 'length' return
      let $arg := $expr?args?*[1]
      (: JNodes of queries and value(); plain paths need no parentheses :)
      let $query := $args[1]?query
      let $nodes := switch () {
        case exists($query) return if (matches($query, '\s')) then `({ $query })` else $query
        case $arg?type = 'function' and $arg?name = 'value' return $args[1]?node
        default return ()
      }
      (: kinds of the selected values, and their presence for each input :)
      let $query-ast := if ($arg?type = 'query') then $arg else $arg?args?*[1]
      let $kinds := $query-ast?kinds
      let $present := $arg?type = 'query' and $arg?present
      (: kinds of values with a length :)
      let $lengths := $kinds[. = ('string', 'array', 'object')]
      let $function := if (count($lengths) = 1) then (
        { 'string': 'string-length', 'array': 'array:size', 'object': 'map:size' }($lengths)
      ) else ()
      let $code := switch () {
        (: no values with a length (or no values at all): nothing :)
        case exists($nodes) and map:contains($query-ast, 'kinds') and empty($lengths) return
          '()'
        (: values of a single kind: function call; missing values yield nothing :)
        case exists($nodes) and exists($function) and count($kinds) = 1 return
          if ($present or $nodes = '.') then `{ $function }({ $nodes })` else `{ $nodes } ! { $function }(.)`
        (: other values are skipped by a type test :)
        case exists($nodes) and exists($function) return
          let $type := { 'string': 'xs:string', 'array': 'array(*)', 'object': 'map(*)' }($lengths)
          let $typed := (if ($nodes = '.') then '' else `{ $nodes }/`) || `self::jnode(*, { $type })`
          return `{ $typed } ! { $function }(.)`
        case exists($nodes) return
          (: string length, or number of members or entries; the context needs no simple map :)
          (: only values with a length: no type test for arrays and maps :)
          let $containers := if (map:contains($query-ast, 'kinds') and (every $kind in $kinds satisfies
            $kind = ('string', 'array', 'object'))) then 'count(*)' else 'self::jnode(*, (array(*) | map(*))) ! count(*)'
          return (if ($nodes = '.') then '' else `{ $nodes } ! `) ||
            `(if (self::jnode(*, xs:string)) then string-length(.) else { $containers })`
        (: literals and other functions: the type is known statically :)
        case $arg?type = 'string' return `string-length({ $args[1]?value })`
        default return '()'
      }
      return { 'value': $code, 'node': `{ $code } ! jtree(.)`, 'idiom': $code, 'nothing': $code = '()' }
    case 'count' return
      let $code := 'count(' || ($args[1]?query otherwise translate:skip('count: no query')) || ')'
      return { 'value': $code, 'node': `jtree({ $code })`, 'idiom': $code }
    case 'value' return
      (: the single selected node, or nothing :)
      let $query := $args[1]?query otherwise translate:skip('value: no query')
      (: single steps need no parentheses :)
      let $node := (if (matches($query, '^[^\s/()\[]+$')) then $query else `({ $query })`) || '[last() = 1]'
      let $code := `{ $node } ! jvalue()`
      (: idiomatic comparisons atomize the JNode :)
      return { 'value': $code, 'node': $node, 'idiom': $node }
    default return
      let $($subject, $pattern) := $expr?args?*
      (: string values of the subject :)
      let $strings := if ($subject?type = 'query') then translate:query-code($subject, $mode, 'xs:string') else ()
      let $code := switch () {
        case exists($strings) and $pattern?type = 'string' return
          (: literal pattern: regex is checked once, string values are selected by type :)
          let $p := $pattern?value
          let $regex := switch () {
            case $name = 'search' return $p
            case contains($p, '|') return `^(?:{ $p })$`
            default return `^{ $p }$`
          }
          return if (try { exists(matches('', $regex)) } catch * { false() }) then (
            `{ $strings }[matches(., { translate:string($regex) })]`
          ) else (
            'false()'
          )
        case ($subject, $pattern)?type = ('number', 'boolean', 'null') return
          'false()'
        case exists($strings) and $pattern?type = ('query', 'function') return
          (: dynamic pattern: string values and string patterns; a missing or invalid pattern raises an error :)
          let $idiomatic := $mode = 'idiomatic'
          let $p := switch () {
            case $idiomatic return $args[2]?node
            case $pattern?type = 'query' return translate:query-code($pattern, $mode, 'xs:string')
            default return `{ $args[2]?node }/self::jnode(*, xs:string)`
          }
          (: relative patterns are bound outside the predicate, which changes the focus :)
          let $relative := some $q in ($pattern, $pattern?args?*)[?type = 'query'] satisfies $q?root != '$'
          let $r := if ($relative) then '$r' else $p
          let $regex := switch () {
            case $name = 'search' return $r
            case $idiomatic return '`^(?:{ ' || $r || ' })$`'
            default return $r || " ! `^(?:{ . })$`"
          }
          let $call := `matches(., { $regex })`
          let $cond := if ($idiomatic) then $call else `try {{ { $call } }} catch * {{ false() }}`
          let $filter := `{ $strings }[{ $cond }]`
          return if ($relative) then `(let $r := { $p } return { $filter })` else $filter
        default return
          let $regex := if ($name = 'match') then "`^(?:{ $r })$`" else '$r'
          return '(some $s in ' || $args[1]?value || ', $r in ' || $args[2]?value ||
            ' satisfies ($s, $r) instance of xs:string+ and ' ||
            '(try { matches($s, ' || $regex || ') } catch * { false() }))'
      }
      return { 'value': $code, 'idiom': $code }
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
