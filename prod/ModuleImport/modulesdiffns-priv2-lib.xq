(:xquery version "4.0";:)
(:*******************************************************:)
(: Test: modulesdiffns-priv2-lib.xq                      :)
(: Written By: Christian Gruen                           :)
(: Purpose: Valid in 4.0, not in 3.1                     :)
(:*******************************************************:)

module namespace defs = "http://www.w3.org/TestModules/diffns-priv2";

declare %private variable $two := 2;

declare %private function local:double($x as xs:integer) { $x * $two };

declare %private function triple($x as xs:integer) { $x * 3 };

declare function defs:f($x as xs:integer) { local:double($x) };

declare function defs:g($x as xs:integer) { triple($x) };
