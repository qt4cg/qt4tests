module namespace shapes = "http://www.xqsharp.com/raytracer/shapes";

import module namespace vector = "http://www.xqsharp.com/raytracer/vector" at "vector.xq";
import module namespace rec = "http://www.xqsharp.com/raytracer/records" at "records.xq";

declare namespace math = "http://www.w3.org/2005/xpath-functions/math";

declare function shapes:intersect(
  $start as xs:double*,
  $dir as xs:double*,
  $shape as (rec:plane | rec:sphere)
) as xs:double? {
  if ($shape instance of rec:sphere)
  then shapes:intersect-sphere($start, $dir, $shape)
  else shapes:intersect-plane($start, $dir, $shape)
};

declare function shapes:normal(
  $position as xs:double*,
  $shape as (rec:plane | rec:sphere)
) as xs:double+ {
  if ($shape instance of rec:sphere)
  then shapes:sphere-normal($position, $shape)
  else $shape?normal
};

declare function shapes:intersect-plane(
  $start as xs:double*,
  $direction as xs:double*,
  $plane as rec:plane
) as xs:double? {
  let $normal := $plane?normal,
      $offset := $plane?offset
  let $denom := vector:dot($direction, $normal)
  where $denom ne 0
  return ($offset - vector:dot($start, $normal) div $denom)[. gt 0]
};

declare function shapes:intersect-sphere(
  $start as xs:double*,
  $direction as xs:double*,
  $sphere as rec:sphere
) as xs:double? {
  let $center := $sphere?center,
      $radius := $sphere?radius
  let $y := vector:sub($start, $center)
  let $beta := vector:dot($direction, $y),
      $gamma := vector:dot($y, $y) - $radius * $radius
  let $discriminant := $beta * $beta - $gamma
  where $discriminant > 0
  return
    let $sqrt := math:sqrt($discriminant)
    return (-$beta - $sqrt, -$beta + $sqrt)[. > 0][1]
};

declare function shapes:sphere-normal(
  $position as xs:double*,
  $sphere as rec:sphere
) as xs:double+ {
  vector:scale(vector:sub($position, $sphere?center), 1 div $sphere?radius)
};
