(:~
 : Text diff: renders the differences of two texts as markup, with word-level changes.
 :
 : 4.0 features: method calls, fn:matching-segments, fn:duplicate-values, braced if,
 : keyword arguments.
 : @author Christian Gruen, BaseX
 :)
import module namespace diff = 'http://qt4cg.org/demos/diff' at 'diff.xqm';
declare namespace markup = 'http://qt4cg.org/demos/diff/markup';

(:~
 : Splits a line into words, whitespace and punctuation characters.
 : @param  $line  line
 : @return tokens
 :)
declare function markup:tokens(
  $line  as xs:string
) as xs:string* {
  matching-segments($line, '\w+|\s+|[^\w\s]')?substring
};

(:~
 : Checks if two lines are similar: at least 40% of their distinct words are shared.
 : @param  $a  old line
 : @param  $b  new line
 : @return result of check
 :)
declare function markup:similar(
  $a  as xs:string,
  $b  as xs:string
) as xs:boolean {
  let $words := fn($line as xs:string) as xs:string* {
    distinct-values(markup:tokens($line)[matches(., '\w')])
  }
  let $x := $words($a)
  let $y := $words($b)
  return 2 * count(duplicate-values(($x, $y))) >= 0.4 * (count($x) + count($y))
};

(:~
 : Renders a word-level diff of two lines.
 : @param  $a  old line
 : @param  $b  new line
 : @return strings and elements
 :)
declare function markup:words(
  $a  as xs:string,
  $b  as xs:string
) as item()* {
  for $block in diff:blocks(diff:edit-script(markup:tokens($a), markup:tokens($b)))
  return if ($block?changed) then (
    if (exists($block?old)) { <del>{ string-join($block?old) }</del> },
    if (exists($block?new)) { <ins>{ string-join($block?new) }</ins> }
  ) else (
    string-join($block?old)
  )
};

(:~
 : Pairs deleted and inserted lines, and renders similar ones as changed lines.
 : @param  $old  deleted lines
 : @param  $new  inserted lines
 : @return paragraphs
 :)
declare function markup:pair(
  $old  as xs:string*,
  $new  as xs:string*
) as element(p)* {
  let $a := head($old)
  let $b := head($new)
  return switch () {
    case empty(($a, $b)) return ()
    case exists($a) and exists($b) and markup:similar($a, $b) return (
      <p class='changed'>{ markup:words($a, $b) }</p>,
      markup:pair(tail($old), tail($new))
    )
    (: no deleted line left, or it resembles a later inserted line: the line was inserted :)
    case empty($a) or (some $later in tail($new) satisfies markup:similar($a, $later)) return (
      <p class='inserted'>{ $b }</p>,
      markup:pair($old, tail($new))
    )
    default return (
      <p class='deleted'>{ $a }</p>,
      markup:pair(tail($old), $new)
    )
  }
};

let $ops := diff:edit-script(diff:lines($diff:OLD), diff:lines($diff:NEW))
return <diff>{
  for $hunk in diff:hunks($ops, context := 1)
  return <hunk header='{ $hunk =?> header() }'>{
    for $block in $hunk?blocks
    return if ($block?changed) then (
      markup:pair($block?old, $block?new)
    ) else (
      $block?old ! <p>{ . }</p>
    )
  }</hunk>
}</diff>
