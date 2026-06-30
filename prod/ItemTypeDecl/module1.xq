(: Name: module1.xq :)
(: Description: A library declaring public and private item type aliases. :)
(: Author: Michael Kay :)
(: Date: 2026-06-30 :)

module namespace lib="http://example.ns/module1";

declare %public type lib:chrono as (xs:date | xs:time);

declare %private type lib:extended-chrono as (lib:chrono | xs:dateTime);

declare type lib:numeric as xs:integer;

declare %public variable $lib:now as lib:extended-chrono := current-dateTime();
