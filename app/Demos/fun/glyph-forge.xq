(:~
 : Glyph forge: a self-keyed cipher cascade that must undo itself.
 : Enum types, labeled records with keyword construction, empty switch,
 : radix pictures, parse-integer, sort-with, partition, items-at,
 : hex/underscore literals and string templates that template regexes.
 :)
declare namespace ξ = 'urn:glyph-forge';

declare type ξ:op as enum('rot', 'mirror', 'zigzag', 'radix');
declare record ξ:step(op as ξ:op, arg as xs:integer := 13);

declare function ξ:apply(
  $text as xs:string,
  $step as ξ:step,
  $dir  as xs:integer
) as xs:string {
  let $chars := characters($text)
  let $n := $step?arg
  return switch ($step?op) {
    case 'rot' return string-join(
      for $c in $chars
      let $cp := string-to-codepoints($c)
      let $base := switch () {
        case $cp = 0x41 to 0x5A return 0x41
        case $cp = 0x61 to 0x7A return 0x61
        default return ()
      }
      return if (exists($base)) then (
        char((($cp - $base + $dir × $n) mod 26 + 26) mod 26 + $base)
      ) else (
        $c
      )
    )
    case 'mirror' return partition($chars, fn($p) { count($p) = $n }) ! reverse(?*) => string-join()
    case 'zigzag' return (
      let $p := 2 × ($n - 1)
      let $rail := fn($i) { (($i - 1) mod $p) -> min((., $p - .)) }
      let $perm := sort-with(1 to count($chars), (
        fn($a, $b) { compare($rail($a), $rail($b)) },
        fn($a, $b) { compare($a, $b) }
      ))
      let $order := if ($dir > 0) then $perm else (1 to count($perm)) ! index-of($perm, .)
      return items-at($chars, $order) => string-join()
    )
    case 'radix' return (
      let $w := (math:log(0x11_0000) div math:log($n)) => ceiling() => xs:integer()
      return if ($dir > 0) then (
        $chars ! format-integer(string-to-codepoints(.), `{ $n }^{ replicate('x', $w) => string-join() }`)
        => string-join()
      ) else (
        tokenize(replace($text, `(.{{{ $w }}})`, '$1 ')) ! char(parse-integer(., $n)) => string-join()
      )
    )
    default return error()
  }
};

let $msg := 'Ouroboros eats ω; the serpent never ends.'
let $key := hash($msg, 'CRC-32') => string() => parse-integer(16)
let $steps := (
  ξ:step('rot', $key mod 26),
  ξ:step('zigzag', 3),
  ξ:step(arg := 4, op := 'mirror'),
  ξ:step('radix', 36)
)
let $stages := fold-left($steps, $msg, fn($acc, $s) { $acc, ξ:apply(foot($acc), $s, 1) })
let $plain := fold-right($steps, foot($stages), fn($s, $t) { ξ:apply($t, $s, -1) })
return (
  `key { $key } ⇒ rot{ $key mod 26 }`,
  for $stage at $i in $stages
  return `{ $i - 1 } { ($steps[$i - 1]?op, '∅')[1] }: { $stage }`,
  `round trip: { $plain eq $msg }`,
  try { ξ:step('rot13') } catch * { `✗ { local-name-from-QName($err:code) }: rot13` }
)
