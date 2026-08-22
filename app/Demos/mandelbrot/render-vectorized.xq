(:~
 : Renders the Mandelbrot set by iterating all points of a row at once.
 : @author Christian Gruen, BaseX
 :)
import module namespace mb = 'http://basex.org/examples/mandelbrot' at 'mandelbrot.xqm';

(:~
 : Escape-time counts for a full row.
 : @param  $cfg  configuration
 : @param  $cxs  real parts of c
 : @param  $cy   imaginary part of c
 : @return counts
 :)
declare function escape(
  $cfg  as mb:config,
  $cxs  as xs:double*,
  $cy   as xs:double
) as xs:integer* {
  (: a single loop advances every point of the row :)
  while-do(
    $cxs ! { 'cx': ., 'zx': 0e0, 'zy': 0e0, 'i': 0, 'done': false() },
    fn($states) { some $state in $states satisfies not($state?done) },
    fn($states) {
      for $state in $states
      return if($state?done) then (
        $state
      ) else (
        let $zx := $state?zx * $state?zx - $state?zy * $state?zy + $state?cx
        let $zy := 2 * $state?zx * $state?zy + $cy
        return {
          'cx'  : $state?cx,
          'zx'  : $zx,
          'zy'  : $zy,
          'i'   : $state?i + 1,
          'done': $zx * $zx + $zy * $zy > 4 or $state?i + 1 >= $cfg?max
        }
      )
    }
  ) ! ?i
};

mb:run-rows(escape#3)
