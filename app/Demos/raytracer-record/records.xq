module namespace rec = "http://www.xqsharp.com/raytracer/records";

(:~ Record types describing a scene.  Vectors and colours are kept as plain
 :  sequences of three xs:double values (x/y/z or r/g/b), which the vector
 :  module operates on directly. :)

(: A camera, resolved to an orthonormal basis (see scene:camera). :)
declare record rec:camera(
  position as xs:double+,
  forward  as xs:double+,
  up       as xs:double+,
  right    as xs:double+
);

(: A point light source with a colour. :)
declare record rec:light(
  position as xs:double+,
  color    as xs:double+
);

(: An infinite plane: points x with dot(x, normal) = offset. :)
declare record rec:plane(
  surface as xs:string,
  normal  as xs:double+,
  offset  as xs:double
);

(: A sphere with the given centre and radius. :)
declare record rec:sphere(
  surface as xs:string,
  center  as xs:double+,
  radius  as xs:double
);

(: A complete scene. :)
declare record rec:scene(
  background as xs:double+,
  shapes     as (rec:plane | rec:sphere)*,
  camera     as rec:camera,
  lights     as rec:light*
);
