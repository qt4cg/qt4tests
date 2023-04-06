xquery version "3.1";
module namespace cmp = "http://www.w3.org/qt4cg/compare";
declare function cmp:compare($x as node(), $y as node()) as xs:boolean {
    if (trace($x, "arg1: " || serialize($x)) and trace($y, "arg2: " || serialize($y)) and  
        $x instance of document-node() and $y instance of document-node()) then
        cmp:compare-content($x, $y)
    else if ($x instance of element() and $y instance of element()) then
        cmp:compare-names($x, $y) and cmp:compare-content($x, $y) and cmp:compare-attributes($x, $y) 
           and (not(has-children($x)) or cmp:compare-string-value($x, $y))
    else if ($x instance of text() and $y instance of text()) then
        cmp:compare-string-value($x, $y)
    else if ($x instance of comment() and $y instance of comment()) then
        cmp:compare-string-value($x, $y)
    else if ($x instance of processing-instruction() and $y instance of processing-instruction()) then
        cmp:compare-names($x, $y) and cmp:compare-string-value($x, $y)
    else trace(false(), "non-matching node kinds") 
    
};
declare function cmp:compare-names($x as node(), $y as node()) as xs:boolean {
   if (node-name($x) eq node-name($y)) then true() else trace(false(), "non-matching node names at " || path($x) || " ~ " || path($y))
};
declare function cmp:compare-content($x as node(), $y as node()) as xs:boolean {
   if (count($x/node()[not(cmp:ignorable(.))]) ne count($y/node()[not(cmp:ignorable(.))]))
   then trace(false(), "different numbers of children at " || path($x) || ":(" || string-join($x!node()!name(), ',') || ") vs (" || string-join($y!node()!name(), ',') || ")") 
   else every $child-comparison in for-each-pair($x/node()[not(cmp:ignorable(.))], $y/node()[not(cmp:ignorable(.))], cmp:compare#2) satisfies $child-comparison
};
declare function cmp:ignorable($x as node()) as xs:boolean {
    $x instance of text() and not(normalize-space($x))
};
declare function cmp:compare-string-value($x as node(), $y as node()) as xs:boolean {
   if (normalize-space($x) eq normalize-space($y)) then true() else trace(false(), "non-matching string-values for " || name($x/..) || " ('" || string($x) || "' vs '" || string($y) || "')")
};
declare function cmp:compare-attributes($x as node(), $y as node()) as xs:boolean {
   if (count($x/@*) ne count($y/@*))
   then trace(false(), "different numbers of attributes on " || name($x) || " (" || count($x/@*) || " vs " || count($y/@*) || ")")
   else let $comparisons := for $a in $x/@*
                            return (if ($y/@*[node-name(.) eq node-name($a) and string(.) eq string($a)])
                                    then true()
                                    else trace(false(), "attribute " || name($a) || " mismatch"))
        return every $c in $comparisons satisfies $c
};
