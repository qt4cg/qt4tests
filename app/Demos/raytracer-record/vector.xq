module namespace vector="http://www.xqsharp.com/raytracer/vector";

declare function vector:add($v1 as xs:double*, $v2 as xs:double*) as xs:double*
{
  for $x at $p in $v1 return ($x + $v2[$p])
};

declare function vector:sub($v1 as xs:double*, $v2 as xs:double*) as xs:double*
{
  for $x at $p in $v1 return ($x - $v2[$p])
};

declare function vector:neg($v as xs:double*)
{
  for $x in $v return (-$x)
};

declare function vector:scale($v as xs:double*, $x as xs:double?) as xs:double*
{
  for $y in $v return ($x * $y)
};

declare function vector:dot($v1 as xs:double*, $v2 as xs:double*) as xs:double
{
  sum(for $x at $p in $v1 return ($x * $v2[$p]))
};

declare function vector:cross($v1 as xs:double*, $v2 as xs:double*) as xs:double*
{
  ($v1[2] * $v2[3] - $v1[3] * $v2[2],
   $v1[3] * $v2[1] - $v1[1] * $v2[3],
   $v1[1] * $v2[2] - $v1[2] * $v2[1])
};

declare function vector:blend($v1 as xs:double*, $v2 as xs:double*) as xs:double*
{
  for $x at $p in $v1 return ($x * $v2[$p])
};


declare function vector:length($v as xs:double*) as xs:double?
{
  math:sqrt(sum(for $x in $v return $x * $x))
};

declare function vector:normalize(
  $v as xs:double*
) as xs:double* {
  let $length := vector:length($v)
  return for $x in $v
         return $x div $length
};

declare function vector:sum-internal(
  $v as xs:double*,
  $stride as xs:integer,
  $remaining as xs:integer,
  $offset as xs:integer
) {
  if ($remaining le $stride)
  then subsequence($v, $offset + 1)
  else
    for $x at $p in vector:sum-internal($v, $stride, $remaining - $stride, $offset + $stride)
    return $x + $v[$offset + $p]
};

declare function vector:sum($v as xs:double*, $stride as xs:integer) as xs:double+
{
  let $c := count($v)
  return
    if ($c = 0)
    then for $x in 1 to $stride return 0
    else vector:sum-internal($v, $stride, $c, 0)
};

