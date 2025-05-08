xquery version "4.0";
(:*******************************************************:)
(: Test: modulesdiffns-priv-lib.xq                       :)
(: Written By: Michael Kay                               :)
(: Purpose: Valid in 4.0, not in 3.1                     :)
(:*******************************************************:)

module namespace defs ="http://www.w3.org/TestModules/diffns-priv";

declare namespace foo = "http://example.org";

declare %private variable $var0 := 1;

declare %private variable $local:var1 := $var0;

declare %private function foo:ff ($x as xs:integer) { $x + $local:var1 };

declare %private variable $foo:var2 := foo:ff(3);

declare %public function defs:f () {$foo:var2};