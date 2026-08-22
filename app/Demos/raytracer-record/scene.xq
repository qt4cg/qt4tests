module namespace scene = "http://www.xqsharp.com/raytracer/scene";

import module namespace vector = "http://www.xqsharp.com/raytracer/vector" at "vector.xq";
import module namespace rec = "http://www.xqsharp.com/raytracer/records" at "records.xq";

(:~
 : Builds a camera from an eye position and a point to look at, deriving the
 : orthonormal basis (forward/up/right) used to cast rays.
 :)
declare function scene:camera(
  $position as xs:double+,
  $look-at as xs:double+
) as rec:camera {
  let $forward := vector:normalize(vector:sub($look-at, $position)),
      $right := vector:normalize(vector:cross($forward, (0, -1, 0))),
      $up := vector:cross($forward, $right)
  return rec:camera($position, $forward, $up, $right)
};

(:~ Returns the scene to be ray-traced. :)
declare function scene:scene() as rec:scene {
  rec:scene(
    (: background :)
    (0, 0, 0),
    (: shapes :)
    (
      rec:plane("checkerboard", (0, 1, 0), 0),
      rec:sphere("shiny", (0, 1, 0), 1),
      rec:sphere("shiny", (-1, 0.5, 1.5), 0.5)
    ),
    (: camera :)
    scene:camera((3, 2, 4), (-1, 0.5, 0)),
    (: lights :)
    (
      rec:light((-2, 2.5, 0), (0.49, 0.07, 0.07)),
      rec:light((1.5, 2.5, 1.5), (0.07, 0.07, 0.49)),
      rec:light((1.5, 2.5, -1.5), (0.07, 0.49, 0.07)),
      rec:light((0, 3.5, 0), (0.21, 0.21, 0.35))
    )
  )
};
