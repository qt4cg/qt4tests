(:~
 : Mandelbrot rendering library.
 : @author Christian Gruen, BaseX
 :)
module namespace mb = 'http://basex.org/examples/mandelbrot';

(:~
 : Image configuration.
 : @param  $width   image width
 : @param  $height  image height
 : @param  $xmin    smallest real value
 : @param  $xmax    largest real value
 : @param  $ymin    smallest imaginary value
 : @param  $ymax    largest imaginary value
 : @param  $max     iteration cap
 : @return configuration
 :)
declare record mb:config(
  width   as xs:integer,
  height  as xs:integer,
  xmin    as xs:double,
  xmax    as xs:double,
  ymin    as xs:double,
  ymax    as xs:double,
  max     as xs:integer
);

(:~
 : Renders the configured image.
 : @param  $escape  escape-time function
 : @return image
 :)
declare function mb:run(
  $escape  as fn(mb:config, xs:double, xs:double) as xs:integer
) as xs:string* {
  let $cfg := mb:load()
  return mb:image($cfg, mb:render($cfg, $escape))
};

(:~
 : Renders the configured image, one row at a time.
 : @param  $escape  escape-time function for a full row
 : @return image
 :)
declare function mb:run-rows(
  $escape  as fn(mb:config, xs:double*, xs:double) as xs:integer*
) as xs:string* {
  let $cfg := mb:load()
  return mb:image($cfg, mb:render-rows($cfg, $escape))
};

(:~
 : Returns the image configuration.
 : @return configuration
 :)
declare %private function mb:load() as mb:config {
  json-doc('config.json', { 'number-format': 'adaptive' })
};

(:~
 : Renders the pixel rows.
 : @param  $cfg     configuration
 : @param  $escape  escape-time function
 : @return pixel rows
 :)
declare function mb:render(
  $cfg     as mb:config,
  $escape  as fn(mb:config, xs:double, xs:double) as xs:integer
) as xs:string* {
  mb:render-rows($cfg, fn($config, $cxs, $cy) { $cxs ! $escape($config, ., $cy) })
};

(:~
 : Renders the pixel rows, one row at a time.
 : @param  $cfg     configuration
 : @param  $escape  escape-time function for a full row
 : @return pixel rows
 :)
declare function mb:render-rows(
  $cfg     as mb:config,
  $escape  as fn(mb:config, xs:double*, xs:double) as xs:integer*
) as xs:string* {
  for $py in 0 to $cfg?height - 1
  let $cy := $cfg?ymin + ($cfg?ymax - $cfg?ymin) * $py div ($cfg?height - 1)
  let $cxs :=
    for $px in 0 to $cfg?width - 1
    return $cfg?xmin + ($cfg?xmax - $cfg?xmin) * $px div ($cfg?width - 1)
  return string-join($escape($cfg, $cxs, $cy) ! mb:color($cfg, .), '  ')
};

(:~
 : Returns the image in PPM format.
 : @param  $cfg    configuration
 : @param  $lines  lines of images
 : @return image
 :)
declare function mb:image(
  $cfg    as mb:config,
  $lines  as xs:string*
) as xs:string* {
  string-join(('P3', $cfg?width, $cfg?height, 255), ' '), $lines
};

(:~
 : Maps the number of iterations to an RGB color triple.
 : @param  $cfg  configuration
 : @param  $i    iterations
 : @return color triple
 :)
declare %private function mb:color($cfg as mb:config, $i as xs:integer) as xs:string {
  let $n := $i * 255 idiv $cfg?max
  let $r := 255 - $n
  let $g := max((0, 255 - $n * $n))
  let $b := max((0, 255 - $n * $n * $n))
  return `{ $r } { $g } { $b }`
};
