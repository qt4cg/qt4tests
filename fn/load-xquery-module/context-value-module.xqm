xquery version "4.0";

module namespace cvm = "http://www.w3.org/fots/fn/load-xquery-module/context-value/module";

declare context value as item()* external;

declare variable $cvm:context := .;

declare function cvm:context-size() as xs:integer {
    count($cvm:context)
};
