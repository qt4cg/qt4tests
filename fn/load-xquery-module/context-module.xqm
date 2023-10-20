xquery version "3.1";

module namespace vm = "http://www.w3.org/fots/fn/load-xquery-module/context/module";
declare namespace fn = "http://www.w3.org/2005/xpath-functions";
declare namespace math = "http://www.w3.org/2005/xpath-functions/math";
declare namespace map = "http://www.w3.org/2005/xpath-functions/map";
declare namespace array = "http://www.w3.org/2005/xpath-functions/array";

declare variable $vm:var1 := "var1";


declare function vm:standard-functions-available() as xs:boolean {
    exists(function-lookup(xs:QName('fn:exists'), 1)) and
    exists(function-lookup(xs:QName('math:pi'), 0)) and
    exists(function-lookup(xs:QName('map:get'), 2)) and
    exists(function-lookup(xs:QName('array:get'), 2))
};

declare function vm:local-functions-available() as xs:boolean {
    exists(function-lookup(xs:QName('vm:standard-functions-available'), 0)) and
    exists(function-lookup(xs:QName('vm:local-functions-available'), 0))
};

declare function vm:saxon-functions-available($expected as xs:boolean) as xs:boolean {
    exists(function-lookup(fn:QName('http://saxon.sf.net/', 'type'), 1)) = $expected
};
