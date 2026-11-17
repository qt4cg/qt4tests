(:~
 : Labyrinth: one dungeon, explored twice (as maps and as XML), then plundered.
 : do-until with positions, map/array/sequence destructuring, for key/value,
 : for member, transitive-closure, sliding windows, while clauses, fn:scan,
 : JNode paths, key punning and try/catch/finally.
 :)
declare namespace μ = 'urn:labyrinth';

declare variable $μ:ROOMS := {
  'atrium':  { 'doors': [ 'library', 'cellar' ], 'gold': 3 },
  'library': { 'doors': [ 'atrium', 'study', 'vault' ], 'gold': 7 },
  'cellar':  { 'doors': [ 'crypt' ], 'gold': 1 },
  'crypt':   { 'doors': [ 'cellar', 'well' ], 'gold': 13 },
  'study':   { 'doors': [ 'library' ], 'gold': 0 },
  'vault':   { 'doors': [], 'gold': 21 },
  'well':    { 'doors': [ 'atrium' ], 'gold': 2 },
  'tower':   { 'doors': [ 'atrium' ], 'gold': 99 }
};

declare function μ:depths(
  $start as xs:string
) as map(xs:string, xs:integer) {
  do-until(
    { 'seen': { $start: 0 }, 'edge': $start },
    fn($state, $pos) {
      let ${ $seen, $edge } := $state
      let $next := distinct-values($edge ! $μ:ROOMS?(.)?doors?*)[not(map:contains($seen, .))]
      return { 'seen': map:merge(($seen, $next ! { (.): $pos })), 'edge': $next }
    },
    fn { empty(?edge) }
  )?seen
};

declare function μ:dungeon() as document-node(element(labyrinth)) {
  document {
    element labyrinth {
      for key $name value $room in $μ:ROOMS
      return element { $name } { attribute gold { $room?gold }, $room?doors?* ! <door to='{ . }'/> }
    }
  }
};

let $depths := μ:depths('atrium')
let $closure := μ:dungeon()/labyrinth/atrium
  => transitive-closure(fn($r) { $r/../*[name() = $r/door/@to] })
let $tour := for key $room value $depth in $depths order by $depth, $room return $room
let $loot := scan($tour ! $μ:ROOMS?(.)?gold, 0, op('+')) ! ?1
return (
  `maps ≡ xml: { deep-equal(sort(map:keys($depths)), sort($closure ! name())) }`,
  `rich rooms: { $μ:ROOMS/*[gold > 10] ! jkey() => sort() => string-join(' ') }`,

  for key $room value $depth in $depths
  let $gold as xs:integer := $μ:ROOMS?($room)?gold
  group by $depth
  order by $depth
  return `depth { $depth }: { sort($room) => string-join(', ') } [{ sum($gold) }◈]`,

  string-join((
    for sliding window $w in $tour
      start $a at $i when true()
      end $b at $j when $j = $i + 1
    where count($w) = 2
    return `{ $a } { if ($b = $μ:ROOMS?($a)?doors?*) then '→' else '⇝' } `,
    foot($tour)
  )),

  for member $pair in array:build($tour, fn($r, $p) { [ $r, $loot[$p + 1] ] })
  let $[ $room, $sum ] := $pair
  while $sum < 30
  count $step
  return `loot { $step }: { $room } ⇒ { $sum }◈`,

  try {
    $depths?tower otherwise error(#μ:sealed, 'the tower is sealed')
  } catch μ:sealed {
    `✗ { $err:map?code }: { $err:description }`
  } finally {
    ()
  }
)
