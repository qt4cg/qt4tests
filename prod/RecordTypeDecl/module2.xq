(: Name: module1.xq :)
(: Description: A library declaring public and private item type aliases. :)
(: Author: Michael Kay :)
(: Date: 2026-06-30 :)

module namespace lib="http://example.ns/module2";

declare %public record lib:chrono (d as xs:date?, t as xs:time?);

declare %public %private type lib:extended-chrono (d as xs:date?, t as xs:time?, tz as xs:duration?);


declare %public variable $lib:now as lib:extended-chrono := 
         {'d': current-date(), 't': current-time(), 'tz': implicit-timezone()};

