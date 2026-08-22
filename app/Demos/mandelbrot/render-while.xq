(:~
 : Renders the Mandelbrot set via fn:while-do.
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
  while-do(
    { 'zx': 0e0, 'zy': 0e0, 'i': 0 },
    fn($s) {
      $s?i < $cfg?max and $s?zx * $s?zx + $s?zy * $s?zy <= 4
    },
    fn($s) {
      {
        'zx': $s?zx * $s?zx - $s?zy * $s?zy + $cx,
        'zy': 2 * $s?zx * $s?zy + $cy,
        'i':  $s?i + 1
      }
    }
  )?i
};

mb:run(escape#3)
