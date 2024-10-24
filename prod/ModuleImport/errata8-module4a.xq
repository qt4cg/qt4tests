(:*******************************************************:)
(: Test: errata8-module2a.xq                             :)
(: Written By: John Snelson                              :)
(: Date: 2009/10/01                                      :)
(: Purpose: Module that imports another module and uses a variable from it, testing circular dependencies pass case :)
(:*******************************************************:)

module namespace errata8_4a="http://www.w3.org/TestModules/errata8_4a";
import module namespace errata8_4b="http://www.w3.org/TestModules/errata8_4b";

declare function errata8_4a:fun()
{
  $errata8_4b:var
};

declare function errata8_4a:fun2()
{
  10
};

