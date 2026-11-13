(: Name: module6.xq :)
(: Description: A library declaring derived record types, cyclically importing module5. :)
(: Author: Christian Gruen :)
(: Date: 2026-11-11 :)

module namespace lib6="http://example.ns/module6";

import module namespace lib5="http://example.ns/module5";

declare record lib6:b extends lib5:a (y);

declare record lib6:c extends lib6:b (z);
