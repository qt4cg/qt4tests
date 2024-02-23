xquery version "4.0";

(:*******************************************************:)
(: Test: test40-lib.xq                                   :)
(: Written By: Michael Kay                               :)
(: Purpose: Libarary module using 4.0 features         ".:)
(:*******************************************************:)

module namespace test40="http://www.w3.org/TestModules/test40";

declare %public function test40:echo(
    $a as xs:string := "(a)",
    $b as xs:string := "(b)",
    $c as xs:string := "(c)") {
    $a || $b || $c
};
