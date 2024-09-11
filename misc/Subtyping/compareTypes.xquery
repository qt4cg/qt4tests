xquery version "4.0";
module namespace sub = "http://www.w3.org/qt4cg/subtyping";
declare %public function sub:isSubtype($a as xs:string, $b as xs:string) as xs:boolean {
    let $module :=  "xquery version '4.0';
                     module namespace cmp = 'http://www.w3.org/qt4cg/compare-inline';
                     declare namespace p1 = 'http://p1.ns/';
                     declare namespace p2 = 'http://p2.ns/';
                     declare variable $cmp:var as item()* external := '';
                     declare function cmp:compareTypes() as xs:boolean {
                         (function() as %TYPE0% {$cmp:var} instance of function() as %TYPE1%)    
                     };"
    let $final-module := $module => replace("%TYPE0%", $a) => replace("%TYPE1%", $b)
    let $functions := load-xquery-module('http://www.w3.org/qt4cg/compare-inline', map{'content':$final-module})?functions
    let $cmp := $functions(fn:QName('http://www.w3.org/qt4cg/compare-inline', 'compareTypes'))?0
    return $cmp()
};

