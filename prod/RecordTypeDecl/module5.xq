(: Name: module5.xq :)
(: Description: A library declaring derived record types, cyclically importing module6. :)
(: Author: Christian Gruen :)
(: Date: 2026-11-11 :)

module namespace lib5="http://example.ns/module5";

import module namespace lib6="http://example.ns/module6";

declare record lib5:a (x);

declare record lib5:d extends lib6:c (w);
