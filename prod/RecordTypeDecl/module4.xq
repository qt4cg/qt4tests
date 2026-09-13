(: Name: module4.xq :)
(: Description: A library declaring public and private item type aliases. :)
(: Author: Michael Kay :)
(: Date: 2026-07-02 :)

module namespace lib="http://example.ns/module4";

declare %public record lib:chronoSupplier (d as lib:dateSupplier, t as lib:timeSupplier);

declare %private record lib:dateTimeSupplier (d as lib:dateSupplier, t as lib:timeSupplier);

declare %private type lib:dateSupplier as fn() as xs:date?;

declare %private type lib:timeSupplier as fn() as xs:time?;

declare %public variable $lib:dateTimeNow as lib:chronoSupplier := {'d': current-date#0, 't': current-time#0};
