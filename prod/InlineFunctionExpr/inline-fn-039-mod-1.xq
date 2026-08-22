module namespace mod-1 = "http://www.w3.org/inline-fn-039-mod-1";

declare function mod-1:g($x as xs:integer) {
   $x + 3
};

declare variable $mod-1:var := 29;