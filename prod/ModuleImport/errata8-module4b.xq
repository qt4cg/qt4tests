(:*******************************************************:)
(: Test: errata8-module2b.xq                             :)
(: Written By: John Snelson                              :)
(: Date: 2009/10/01                                      :)
(: Purpose: Module that imports another module and uses a function from it, testing circular dependencies :)
(:*******************************************************:)

module namespace errata8_4b="http://www.w3.org/TestModules/errata8_4b";
import module namespace errata8_4a="http://www.w3.org/TestModules/errata8_4a";

declare variable $errata8_4b:var := errata8_4a:fun2#0();
