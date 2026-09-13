(: Name: module3.xq :)
(: Description: A library declaring public and private record types. :)
(: Author: Michael Kay :)
(: Date: 2026-06-30 :)

module namespace lib="http://example.ns/module3";

declare %public record lib:chrono (d as xs:date?, t as xs:time?);

declare %public record Q{http://example.ns/module3-and-a-half}extended-chrono (d as xs:date, t as xs:time, tz as xs:duration);

declare %public variable $lib:now as lib:chrono := {'d': current-date()};
