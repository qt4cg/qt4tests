(: Name: module4.xq :)
(: Description: A library declaring public and private item type aliases. :)
(: Author: Michael Kay :)
(: Date: 2026-07-02 :)

module namespace lib="http://example.ns/module4";

declare %public type lib:chronoSupplier as (lib:dateSupplier | lib:timeSupplier);

declare %public type lib:dateTimeSupplier as fn() as record(date as lib:dateSupplier, time as lib:timeSupplier);

declare %private type lib:dateSupplier as fn() as xs:date;

declare %private type lib:timeSupplier as fn() as xs:time;

declare %public variable $lib:dateNow as lib:dateSupplier := current-date#0;

declare %public variable $lib:timeNow as lib:timeSupplier := current-time#0;

declare %public variable $lib:dateTimeNow as lib:dateTimeSupplier := fn(){{"date": current-date#0, "time": current-time#0}};
