(:~
 : Renders the Mandelbrot set via function composition.
 : @author Christian Gruen, BaseX
 :)
import module namespace mb = 'http://basex.org/examples/mandelbrot' at 'mandelbrot.xqm';

(:~
 : Iteration state.
 : @param  $zx    real part of z
 : @param  $zy    imaginary part of z
 : @param  $i     current iteration
 : @param  $done  escaped flag
 : @return state
 :)
declare record state(
  zx    as xs:double,
  zy    as xs:double,
  i     as xs:integer,
  done  as xs:boolean
);

(:~
 : Escape-time count for a single point.
 : @param  $cfg  configuration
 : @param  $cx   real part of c
 : @param  $cy   imaginary part of c
 : @return count
 :)
declare function escape(
  $cfg  as mb:config,
  $cx   as xs:double,
  $cy   as xs:double
) as xs:integer {
  let $step := fn($state as state) as state {
    if($state?done) then (
      $state
    ) else (
      let $zx := $state?zx * $state?zx - $state?zy * $state?zy + $cx
      let $zy := 2 * $state?zx * $state?zy + $cy
      return state($zx, $zy, $state?i + 1, $zx * $zx + $zy * $zy > 4)
    )
  }
  (: the step function is composed with itself, once per iteration :)
  let $iterate := fold-left(
    1 to $cfg?max,
    identity#1,
    fn($composed, $_) { fn($state as state) as state { $step($composed($state)) } }
  )
  return $iterate(state(0e0, 0e0, 0, false()))?i
};

mb:run(escape#3)
