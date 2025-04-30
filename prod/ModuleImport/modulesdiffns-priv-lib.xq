(:*******************************************************:)
(: Test: modulesdiffns-priv-lib.xq                       :)
(: Written By: Carmelo Montanez                          :)
(: Purpose: Valid in 4.0, not in 3.1                     :)
(:*******************************************************:)

module namespace defs ="http://www.w3.org/TestModules/diffns-priv";

declare namespace foo = "http://example.org";

declare %private variable $foo:var1 := 1;

declare %public function $defs:f {$foo:var1};