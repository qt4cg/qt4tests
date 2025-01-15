(:*******************************************************:)
(: Test: test1-lib.xq                                    :)
(: Written By: Michael Kay                               :)
(: Date: 2025/01/15 14:47:00                             :)
(: Purpose: Simple library module with dynamic error     :)
(:*******************************************************:)

module namespace test1="http://www.w3.org/TryCatchExpr/test1";

declare variable $test1:flag := 1;

declare function test1:ok () 
{
    1 + <_/> 
};
