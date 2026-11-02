(:~
 : Text diff: renders the differences of two texts in the unified diff format.
 :
 : 4.0 features: method calls, keyword arguments, string templates.
 : @author Christian Gruen, BaseX
 :)
import module namespace diff = 'http://qt4cg.org/demos/diff' at 'diff.xqm';

let $ops := diff:edit-script(diff:lines($diff:OLD), diff:lines($diff:NEW))
return (
  '--- old',
  '+++ new',
  for $hunk in diff:hunks($ops, context := 1)
  return (
    $hunk =?> header(),
    for $block in $hunk?blocks
    return if ($block?changed) then (
      $block?old ! `-{ . }`,
      $block?new ! `+{ . }`
    ) else (
      $block?old ! ` { . }`
    )
  )
)
