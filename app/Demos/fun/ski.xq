(:~
 : SKI: arithmetic built from three combinators and nothing else.
 : Church numerals, curried closures, thunked booleans, a method-based
 : fixpoint, lower-arity callbacks, mapping arrows and pipelines.
 :)
declare namespace λ = 'urn:untyped-lambda';

declare variable $λ:S := fn($x) { fn($y) { fn($z) { $x($z)($y($z)) } } };
declare variable $λ:K := fn($x) { fn($y) { $x } };
declare variable $λ:I := $λ:S($λ:K)($λ:K);
declare variable $λ:B := $λ:S($λ:K($λ:S))($λ:K);
declare variable $λ:ZERO := $λ:K($λ:I);
declare variable $λ:SUCC := $λ:S($λ:B);
declare variable $λ:PLUS := fn($m) { $m($λ:SUCC) };
declare variable $λ:TIMES := $λ:B;
declare variable $λ:POW := fn($b) { fn($e) { $e($b) } };
declare variable $λ:PRED := fn($n) { fn($f) { fn($x) {
  $n(fn($g) { fn($h) { $h($g($f)) } })($λ:K($x))($λ:I)
} } };
declare variable $λ:IS-ZERO := fn($n) { $n($λ:K($λ:K($λ:I)))($λ:K) };

declare function λ:church(
  $n as xs:integer
) as fn(*) {
  fold-left(1 to $n, $λ:ZERO, $λ:SUCC)
};

declare function λ:int(
  $c as fn(*)
) as xs:integer {
  $c(fn { . + 1 })(0)
};

let $Ω := {
  'fact': fn($self, $n) {
    $λ:IS-ZERO($n)
      (fn() { $λ:SUCC($λ:ZERO) })
      (fn() { $λ:TIMES($n)($self =?> fact($λ:PRED($n))) })
      ()
  }
}
return (
  for $n in 0 to 4
  let $c := λ:church($n)
  return `{ $n }: { (
    $λ:PLUS($c)($c), $λ:TIMES($c)($c), $λ:POW($c)($c), $Ω =?> fact($c), $λ:PRED($c)
  ) =!> λ:int() => string-join(' ') }`,

  5 -> λ:church(.) -> $Ω =?> fact(.) -> λ:int(.) -> `5! = { . }`,

  while-do(0, fn { λ:int($Ω =?> fact(λ:church(.))) <= 1_000 }, op('+')(?, 1))
  -> `first n with n! > 1,000: { . }`
)
