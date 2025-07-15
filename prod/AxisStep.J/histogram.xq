
xquery version "4.0";
module namespace ax="http://www.w3.org/TestModules/AxisStepJ/Histogram";

declare function ax:histogram($origin as jnode-type()) as map(xs:string, xs:integer) {
  map {
    "ancestor": count($origin/ancestor::*),
    "ancestor-or-self": count($origin/ancestor-or-self::*),
    "child": count($origin/child::*),
    "descendant": count($origin/descendant::*),
    "descendant-or-self": count($origin/descendant-or-self::*),
    "following": count($origin/following::*),
    "following-or-self": count($origin/following-or-self::*),
    "following-sibling": count($origin/following-sibling::*),
    "following-sibling-or-self": count($origin/following-sibling-or-self::*),
    "parent": count($origin/parent::*),
    "preceding": count($origin/preceding::*),
    "preceding-or-self": count($origin/preceding-or-self::*),
    "preceding-sibling": count($origin/preceding-sibling::*),
    "preceding-sibling-or-self": count($origin/preceding-sibling-or-self::*),
    "self": count($origin/self::*)
  }
};
