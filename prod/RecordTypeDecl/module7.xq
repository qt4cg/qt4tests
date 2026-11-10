(: Name: module7.xq :)
(: Description: A library declaring a derived record type, cyclically importing module8. :)
(: Author: Christian Gruen :)
(: Date: 2026-11-11 :)

module namespace lib7="http://example.ns/module7";

import module namespace lib8="http://example.ns/module8";

declare record lib7:a extends lib8:b (x);
