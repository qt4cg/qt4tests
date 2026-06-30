(: Name: module1.xq :)
(: Description: A library declaring public and private item type aliases. :)
(: Author: Michael Kay :)
(: Date: 2026-06-30 :)

module namespace lib="http://example.ns/module3";

declare %public type lib:chrono as (xs:date | xs:time);

declare %public type Q{http://example.ns/module3-and-a-half}extended-chrono as (lib:chrono | xs:dateTime);

declare %public variable $lib:now as lib:chrono := current-date();
