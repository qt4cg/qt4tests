xquery version "4.0";

module namespace tm = "http://www.w3.org/fots/fn/load-xquery-module/trusted/module";

declare function tm:f() {
  exists(doc('../../docs/bib.xml')/*/*)
};
