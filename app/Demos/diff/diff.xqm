(:~
 : Text diff: computes the differences of two sequences with the Myers algorithm.
 :
 : 4.0 features: enums, records with methods, map destructuring, map:build, fn:while-do,
 : fn:fold-right, fn:partition, fn:index-where, fn:items-at, fn:slice with steps,
 : braced if.
 : @author Christian Gruen, BaseX
 :)
module namespace diff = 'http://qt4cg.org/demos/diff';

(:~ Kind of an edit operation: unchanged, deleted or inserted. :)
declare type diff:kind as enum('=', '-', '+');

(:~ Edit operation. :)
declare record diff:op(
  kind  as diff:kind,
  text  as xs:string
);

(:~ Block of a hunk: unchanged lines, or deleted and inserted lines. :)
declare record diff:block(
  changed  as xs:boolean,
  old      as xs:string*,
  new      as xs:string*
);

(:~ Hunk: lines before the hunk, blocks, and a method that returns the unified diff header. :)
declare record diff:hunk(
  old-offset  as xs:integer,
  new-offset  as xs:integer,
  blocks      as diff:block*,
  header      as fn(diff:hunk) as xs:string := fn {
    let $range := fn($offset as xs:integer, $lines as xs:string*) as xs:string {
      `{ $offset + (if (exists($lines)) then 1 else 0) },{ count($lines) }`
    }
    return `@@ -{ $range(?old-offset, ?blocks?old) } +{ $range(?new-offset, ?blocks?new) } @@`
  }
);

(:~ Position and operations of the backward walk through the edit graph. :)
declare record diff:walk(
  x    as xs:integer,
  y    as xs:integer,
  ops  as diff:op*
);

(:~ Old sample text. :)
declare variable $diff:OLD := 'Pancakes for four people
Ingredients: flour, milk, eggs, sugar, salt
Mix the flour with the sugar and the salt.
Whisk the eggs into the milk.
Combine both mixtures and stir until smooth.
Let the batter rest for ten minutes.
Heat a pan with a little butter.
Pour in a ladle of batter.
Bake each side until golden.
Keep the pancakes warm in the oven.
Serve with jam or maple syrup.
Enjoy your meal!';

(:~ New sample text. :)
declare variable $diff:NEW := 'Pancakes for four people
Ingredients: flour, milk, eggs, sugar, salt, butter
Mix the flour with the sugar and the salt.
Whisk the eggs into the milk.
Combine both mixtures and stir until smooth.
Let the batter rest for thirty minutes.
Heat a pan with a little butter.
Pour in a ladle of batter.
Bake each side until golden.
Serve with jam or maple syrup.
Sprinkle with powdered sugar.
Enjoy your meal!';

(:~
 : Splits a text into lines.
 : @param  $text  text
 : @return lines
 :)
declare function diff:lines(
  $text  as xs:string
) as xs:string* {
  tokenize($text, '\r?\n')
};

(:~
 : Computes the shortest edit script of two sequences with the Myers algorithm.
 : @param  $old  old items
 : @param  $new  new items
 : @return operations
 :)
declare function diff:edit-script(
  $old  as xs:string*,
  $new  as xs:string*
) as diff:op* {
  let $n := count($old)
  let $m := count($new)
  (: for each number of differences, the furthest position in $old per diagonal (x - y) :)
  let $trace := while-do(
    { 1: 0 },
    fn($trace) { (foot($trace)?($n - $m) otherwise -1) < $n },
    fn($trace) {
      let $d := count($trace) - 1
      let $v := foot($trace)
      return ($trace, map:build(slice(-$d to $d, step := 2), value := fn($k) {
        let $x := if (diff:down($v, $k, $d)) then $v?($k + 1) else $v?($k - 1) + 1
        return diff:snake($old, $new, $x, $x - $k)
      }))
    }
  )
  (: walk back from the end, and prepend each change and the unchanged items after it :)
  return fold-right(0 to count($trace) - 2, diff:walk($n, $m, ()), fn($d, $walk) {
    let ${ $x, $y, $ops } := $walk
    let $v := $trace[$d + 1]
    let $k := $x - $y
    let $down := diff:down($v, $k, $d)
    let $pk := if ($down) then $k + 1 else $k - 1
    let $px := $v?$pk
    let $py := $px - $pk
    let $equal := min(($x - $px, $y - $py))
    return diff:walk($px, $py, (
      if ($d > 0) {
        if ($down) then (
          diff:op('+', $new[$py + 1])
        ) else (
          diff:op('-', $old[$px + 1])
        )
      },
      items-at($old, $x - $equal + 1 to $x) ! diff:op('=', .),
      $ops
    ))
  })?ops
};

(:~
 : Checks if the Myers algorithm moves down (insertion) instead of right (deletion).
 : @param  $v  furthest positions per diagonal
 : @param  $k  diagonal
 : @param  $d  number of differences
 : @return result of check
 :)
declare function diff:down(
  $v  as map(xs:integer, xs:integer),
  $k  as xs:integer,
  $d  as xs:integer
) as xs:boolean {
  $k = -$d or ($k != $d and $v?($k - 1) < $v?($k + 1))
};

(:~
 : Follows a diagonal of the Myers algorithm as long as the items of both sequences are equal.
 : @param  $old  old items
 : @param  $new  new items
 : @param  $x    position in the old items
 : @param  $y    position in the new items
 : @return position in the old items after the equal items
 :)
declare function diff:snake(
  $old  as xs:string*,
  $new  as xs:string*,
  $x    as xs:integer,
  $y    as xs:integer
) as xs:integer {
  if ($old[$x + 1] = $new[$y + 1]) then diff:snake($old, $new, $x + 1, $y + 1) else $x
};

(:~
 : Groups the operations into hunks: changes with the given number of unchanged lines around them.
 : @param  $ops      operations
 : @param  $context  number of unchanged lines
 : @return hunks
 :)
declare function diff:hunks(
  $ops      as diff:op*,
  $context  as xs:integer
) as diff:hunk* {
  let $changes := index-where($ops, fn { ?kind != '=' })
  for $group in partition($changes, fn($group, $change) { $change - foot($group) > 2 * $context })
  let $start := max((1, array:head($group) - $context))
  let $before := $ops[position() < $start]
  return diff:hunk(
    count($before[?kind != '+']),
    count($before[?kind != '-']),
    diff:blocks(slice($ops, start := $start, end := array:foot($group) + $context))
  )
};

(:~
 : Groups operations into blocks: runs of unchanged items, and runs of deleted and inserted items.
 : @param  $ops  operations
 : @return blocks
 :)
declare function diff:blocks(
  $ops  as diff:op*
) as diff:block* {
  for $run in partition($ops, fn($run, $op) { (foot($run)?kind = '=') != ($op?kind = '=') })
  let $run-ops := $run?*
  return diff:block(
    head($run-ops)?kind != '=',
    $run-ops[?kind != '+']?text,
    $run-ops[?kind != '-']?text
  )
};
