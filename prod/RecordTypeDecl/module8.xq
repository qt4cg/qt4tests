(: Name: module8.xq :)
(: Description: A library declaring a derived record type, cyclically importing module7. :)
(: Author: Christian Gruen :)
(: Date: 2026-11-11 :)

module namespace lib8="http://example.ns/module8";

import module namespace lib7="http://example.ns/module7";

declare record lib8:b extends lib7:a (y);
