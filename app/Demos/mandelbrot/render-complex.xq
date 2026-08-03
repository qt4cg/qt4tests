(:~
 : Renders the Mandelbrot set via complex-number records.
 : @author Christian Gruen, BaseX
 :)
import module namespace mb = 'http://basex.org/examples/mandelbrot' at 'mandelbrot.xqm';

declare namespace c = 'http://basex.org/examples/mandelbrot/complex';

(:~
 : A complex number.
 : @param  $re  real part
 : @param  $im  imaginary part
 : @return complex number
 :)
declare record c:number(
  re  as xs:double,
  im  as xs:double
);

(:~
 : Adds two complex numbers.
 : @param  $a  first number
 : @param  $b  second number
 : @return sum
 :)
declare function c:add($a as c:number, $b as c:number) as c:number {
  c:number($a?re + $b?re, $a?im + $b?im)
};

(:~
 : Multiplies two complex numbers.
 : @param  $a  first number
 : @param  $b  second number
 : @return product
 :)
declare function c:multiply($a as c:number, $b as c:number) as c:number {
  c:number($a?re * $b?re - $a?im * $b?im, $a?re * $b?im + $a?im * $b?re)
};

(:~
 : Returns the squared modulus of a complex number.
 : @param  $a  number
 : @return squared modulus
 :)
declare function c:norm($a as c:number) as xs:double {
  $a?re * $a?re + $a?im * $a?im
};

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
  let $c := c:number($cx, $cy)
  return while-do(
    { 'z': c:number(0e0, 0e0), 'i': 0 },
    fn($state) { $state?i < $cfg?max and c:norm($state?z) <= 4 },
    fn($state, $pos) { {
      'z': c:add(c:multiply($state?z, $state?z), $c),
      'i': $pos
    } }
  )?i
};

mb:run(escape#3)
