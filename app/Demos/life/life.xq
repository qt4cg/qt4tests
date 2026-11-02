(:~
 : Conway’s Game of Life on a torus: runs generations until a pattern repeats.
 :
 : 4.0 features: array:build, fn:items-at, fn:slice, fn:do-until,
 : but with, map destructuring.
 : @author Christian Gruen, BaseX
 :)
declare namespace life = 'http://qt4cg.org/demos/life';

(:~ Initial pattern: a glider. :)
declare variable $life:PATTERN := (
  '.#......',
  '..#.....',
  '###.....',
  '........',
  '........',
  '........',
  '........',
  '........'
);

(:~ Board width. :)
declare variable $life:WIDTH := string-length(head($life:PATTERN));

(:~ Board height. :)
declare variable $life:HEIGHT := count($life:PATTERN);

(:~ Neighbor positions of each cell, with wrap-around at the edges. :)
declare variable $life:NEIGHBORS := array:build(
  0 to $life:WIDTH * $life:HEIGHT - 1,
  fn($cell) {
    let $x := $cell mod $life:WIDTH
    let $y := $cell idiv $life:WIDTH
    for $dy in -1 to 1
    for $dx in -1 to 1
    where $dx != 0 or $dy != 0
    return (($y + $dy + $life:HEIGHT) mod $life:HEIGHT) * $life:WIDTH
      + ($x + $dx + $life:WIDTH) mod $life:WIDTH + 1
  }
);

(:~ Board state: generation, cells, their string key, and the generations of all boards seen so far. :)
declare record life:state(
  generation  as xs:integer,
  cells       as xs:boolean*,
  key         as xs:string,
  seen        as map(xs:string, xs:integer)
);

(:~
 : Computes the next generation.
 : @param  $cells  cells
 : @return new cells
 :)
declare function life:step(
  $cells  as xs:boolean*
) as xs:boolean* {
  for $alive at $c in $cells
  let $count := count(items-at($cells, $life:NEIGHBORS?$c)[.])
  return $count = 3 or $alive and $count = 2
};

(:~
 : Serializes cells to a string key.
 : @param  $cells  cells
 : @return string
 :)
declare function life:key(
  $cells  as xs:boolean*
) as xs:string {
  string-join($cells ! (if (.) then '#' else '.'))
};

(:~
 : Renders cells as rows.
 : @param  $cells  cells
 : @return rows
 :)
declare function life:render(
  $cells  as xs:boolean*
) as xs:string* {
  for $y in 0 to $life:HEIGHT - 1
  return life:key(slice($cells, start := $y * $life:WIDTH + 1, end := ($y + 1) * $life:WIDTH))
};

let $start := $life:PATTERN ! characters(.) ! (. = '#')
let ${ $generation, $cells, $key, $seen } := do-until(
  life:state(0, $start, life:key($start), {}),
  fn($state as life:state) as life:state {
    let $cells := life:step($state?cells)
    return $state but with {
      'generation': $state?generation + 1,
      'cells': $cells,
      'key': life:key($cells),
      'seen': map:put($state?seen, $state?key, $state?generation)
    }
  },
  fn { map:contains(?seen, ?key) }
)
let $first := $seen?$key
return (
  life:render($cells),
  `Generation { $generation } repeats generation { $first } (period { $generation - $first }).`
)
