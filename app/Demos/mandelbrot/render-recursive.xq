(:~
 : Renders the Mandelbrot set via a recursive function.
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
  escape($cfg, $cx, $cy, 0.0, 0.0, 0)
};

(:~
 : Recursive computation of escape-time count.
 : @param  $cfg  configuration
 : @param  $cx   real part of c
 : @param  $cy   imaginary part of c
 : @param  $zx   real part of z
 : @param  $zy   imaginary part of z
 : @param  $i    current iteration
 : @return count
 :)
declare function escape(
  $cfg  as mb:config,
  $cx   as xs:double,
  $cy   as xs:double,
  $zx   as xs:double,
  $zy   as xs:double,
  $i    as xs:integer
) as xs:integer {
  if($i >= $cfg?max or $zx * $zx + $zy * $zy > 4) then (
    $i
  ) else (
    escape($cfg, $cx, $cy, $zx * $zx - $zy * $zy + $cx, 2 * $zx * $zy + $cy, $i + 1)
  )
};

mb:run(escape#3)
