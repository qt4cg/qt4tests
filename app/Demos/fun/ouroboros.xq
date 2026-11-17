(:~
 : Ouroboros: a shape hierarchy whose methods eat their own tails.
 : Labeled records, inheritance, fixed methods, integrity constraints,
 : method calls, but-with updates, coercion and a self-swallowing serpent.
 :)
declare namespace ω = 'urn:ouroboros';

declare record ω:shape(
  scale as xs:double := 1,
  %fixed area as fn(ω:shape) as xs:double := fn { 0 },
  %fixed grow as fn(ω:shape, xs:double) as ω:shape := fn($s, $k) {
    $s but with { 'scale': $s?scale × $k }
  },
  %fixed swallow as fn(ω:shape) as ω:shape* := fn($s) {
    if ($s =?> area() < 1e-2) then $s else (
      $s, $s =?> grow(0.25 + abs(math:sin($s?scale)) div 2) =?> swallow()
    )
  }
) where ?scale > 0;

declare record ω:circle extends ω:shape(
  r as xs:double,
  %fixed area := fn { math:pi() × math:pow(?r × ?scale, 2) }
) where ?r >= 0;

declare record ω:square extends ω:shape(
  side as xs:double,
  %fixed area := fn { (?side × ?scale) => math:pow(2) }
);

declare record ω:serpent extends ω:shape(
  tail as ω:shape*,
  %fixed area := fn { ?scale × (?tail =?> area() => sum()) }
);

let $zoo := (
  ω:circle(r := 1),
  ω:square(side := 3, scale := 0.5),
  ω:serpent(tail := ω:circle(r := 2) =?> swallow()),
  { 'r': 0.5, 'scale': 2 } coerce as ω:circle
)
for $beast at $i in $zoo
let $kind := typeswitch ($beast) {
  case ω:circle return '◯'
  case ω:square return '□'
  case ω:serpent return `∿{ count($beast?tail) }`
  default return '?'
}
let $meals := $beast =?> swallow()
return `{ $i } { $kind }: { count($meals) } bites, { $meals =?> area() =!> round(3) => string-join(' → ') }`,

for $bad in (fn() { ω:circle(r := -1) }, fn() { ω:square(side := 1, scale := 0) })
return try { $bad() } catch * { '✗ rejected' }
