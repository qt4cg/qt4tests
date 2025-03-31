xquery version "4.0";

(:*******************************************************:)
(: Test: test43-a.xq                                   :)
(: Written By: Michael Kay                               :)
(: Purpose: Libarary module using 4.0 features         ".:)
(:*******************************************************:)

module namespace test43a="http://www.w3.org/TestModules/test43a";
import module namespace test43b = 'http://www.w3.org/TestModules/test43b';
declare %public type test43a:t1 as test43b:t2;
declare %public type test43a:t2 as xs:integer;
