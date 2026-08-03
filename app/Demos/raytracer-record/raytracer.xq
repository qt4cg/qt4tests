module namespace raytracer = "http://www.xqsharp.com/raytracer";

import module namespace vector = "http://www.xqsharp.com/raytracer/vector" at "vector.xq";
import module namespace shapes = "http://www.xqsharp.com/raytracer/shapes" at "shapes.xq";
import module namespace materials = "http://www.xqsharp.com/raytracer/materials" at "materials.xq";
import module namespace rec = "http://www.xqsharp.com/raytracer/records" at "records.xq";

declare namespace math = "http://www.w3.org/2005/xpath-functions/math";

(:~
 : Returns the color of a pixel in the ray-traced image.
 :
 : @param $scene The scene to draw
 : @param $x The x co-ordinate of the pixel (usually from -1 to 1,
 :           although the range can be increased for wide aspect ratios).
 : @param $y The y co-ordinate of the pixel (usually from -1 to 1,
 :           although the range can be increased for tall aspect ratios).
 : @return A list of three xs:double values representing the red, green
 :         and blue channels, in the range [0, 1].
 :)
declare function raytracer:plot-pixel(
  $scene as rec:scene,
  $x as xs:double,
  $y as xs:double
) as xs:double+ {
  let $camera := $scene?camera
  let $ray-source := $camera?position,
      $ray-direction := vector:normalize(
                          vector:add(
                            $camera?forward,
                            vector:add(
                              vector:scale($camera?right, $x),
                              vector:scale($camera?up, $y))))
  for $channel in raytracer:trace-ray($scene, $ray-source, $ray-direction, (), 1)
  return if ($channel lt 0) then 0
         else if ($channel gt 1) then 1
         else $channel
};

(: Shapes are identified by their position in $scene?shapes.  The optional
 : $ignore index is the shape a ray originates from, skipped to avoid
 : self-intersection. :)
declare function raytracer:trace-ray(
  $scene as rec:scene,
  $source as xs:double*,
  $direction as xs:double*,
  $ignore as xs:integer?,
  $contribution as xs:double
) as xs:double* {
  subsequence(
    (
      for $shape at $index in $scene?shapes
      where not($index = $ignore)
      let $distance := shapes:intersect($source, $direction, $shape)
      let $position := vector:add($source, vector:scale($direction, $distance))
      where exists($distance)
      order by $distance
      return
        raytracer:shade($position, $direction, $shape, $index, $scene, $contribution)
    ,
      $scene?background
    ),
    1,
    3)
};

declare function raytracer:test-ray(
  $scene as rec:scene,
  $source as xs:double*,
  $direction as xs:double*,
  $ignore as xs:integer
) as xs:double* {
  for $shape at $index in $scene?shapes
  where not($index = $ignore)
  return shapes:intersect($source, $direction, $shape)
};

declare function raytracer:shade(
  $position as xs:double*,
  $direction as xs:double*,
  $shape as (rec:plane | rec:sphere),
  $index as xs:integer,
  $scene as rec:scene,
  $contribution as xs:double
) as xs:double* {
  let $material := materials:material($shape?surface, $position)
  let $normal := shapes:normal($position, $shape)
  let $normal := if (vector:dot($direction, $normal) > 0) then vector:neg($normal) else $normal
  let $reflected-direction := vector:sub($direction,
                                vector:scale($normal,
                                  2 * vector:dot($normal, $direction)))
  let $surface-reflectiveness := $material[4]
  let $contribution := $contribution * $surface-reflectiveness
  return
    vector:sum(
      (
        raytracer:light($scene, $index, $position, $normal, $reflected-direction, $material)
      ,
        vector:scale(
          raytracer:trace-ray($scene,
                              $position,
                              $reflected-direction,
                              $index,
                              $contribution)[$contribution gt 0.01],
          $surface-reflectiveness)
      ), 3)
};

declare function raytracer:light(
  $scene as rec:scene,
  $ignore as xs:integer,
  $position as xs:double*,
  $normal as xs:double*,
  $reflected-direction as xs:double*,
  $material as xs:double*
) {
  let $surface-color := subsequence($material, 1, 3),
      $surface-reflectiveness := $material[4],
      $surface-smoothness := $material[5]
  return
    vector:sum(
      for $light in $scene?lights
      let $light-color := $light?color,
          $light-position := $light?position,
          $light-direction := vector:normalize(
                                vector:sub($light-position, $position)),
          $light-distance := vector:length(
                               vector:sub($light-position, $position))
      let $illumination := vector:dot($light-direction, $normal)
      let $specular := vector:dot($light-direction, $reflected-direction)
      where not(raytracer:test-ray($scene, $position, $light-direction, $ignore) <
                $light-distance)
      return
      (
        vector:scale(vector:blend($light-color, $surface-color),
                     $illumination)[$illumination gt 0],

        vector:scale(
          $light-color,
          math:pow($specular, $surface-smoothness) * $surface-reflectiveness
        )[$specular gt 0]
      ),
      3
    )
};
