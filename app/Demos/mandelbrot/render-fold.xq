(:~
 : Renders the Mandelbrot set via fn:fold-left.
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
  fold-left(
    1 to $cfg?max,
    { 'zx': 0e0, 'zy': 0e0, 'i': 0, 'done': false() },
    fn($state, $i) {
      if($state?done) then (
        $state
      ) else (
        let $zx := $state?zx * $state?zx - $state?zy * $state?zy + $cx
        let $zy := 2 * $state?zx * $state?zy + $cy
        return {
          'zx'  : $zx,
          'zy'  : $zy,
          'i'   : $i,
          'done': $zx * $zx + $zy * $zy > 4
        }
      )
    }
  )?i
};

mb:run(escape#3)
