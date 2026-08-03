(:~
 : Renders the Mandelbrot set via anonymous recursion.
 : @author Christian Gruen, BaseX
 :)
import module namespace mb = 'http://basex.org/examples/mandelbrot' at 'mandelbrot.xqm';

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
  (: an inline function cannot refer to itself: it is passed to itself instead :)
  let $iterate := fn($self, $zx, $zy, $i) {
    if($i >= $cfg?max or $zx * $zx + $zy * $zy > 4) then (
      $i
    ) else (
      $self($self, $zx * $zx - $zy * $zy + $cx, 2 * $zx * $zy + $cy, $i + 1)
    )
  }
  return $iterate($iterate, 0e0, 0e0, 0)
};

mb:run(escape#3)
