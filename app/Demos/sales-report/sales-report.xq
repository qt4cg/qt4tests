(:~
 : Sales report: parses CSV data and summarizes it by region and month.
 :
 : 4.0 features: fn:parse-csv, method calls, pipelines, fn:sort-by,
 : fn:partition, fn:scan, fn:highest, fn:lowest, while clauses.
 : @author Christian Gruen, BaseX
 :)
declare namespace sr = 'http://qt4cg.org/demos/sales-report';

(:~ Sale, with methods for the revenue and the month. :)
declare record sr:sale(
  date      as xs:date,
  region    as xs:string,
  product   as xs:string,
  quantity  as xs:integer,
  price     as xs:decimal,
  revenue   as fn(sr:sale) as xs:decimal := fn { ?quantity * ?price },
  month     as fn(sr:sale) as xs:string := fn { format-date(?date, '[Y]-[M01]') }
);

(:~ Sales data. :)
declare variable $sr:CSV := 'date,region,product,quantity,price
2026-01-05,North,Kettle,4,24.90
2026-01-09,South,Toaster,2,39.50
2026-01-17,North,Toaster,1,39.50
2026-01-28,West,Blender,3,59.00
2026-02-02,South,Kettle,6,24.90
2026-02-11,West,Kettle,2,24.90
2026-02-14,North,Blender,2,59.00
2026-02-25,South,Blender,1,59.00
2026-03-03,West,Toaster,5,39.50
2026-03-08,North,Kettle,3,24.90
2026-03-19,South,Toaster,4,39.50
2026-03-30,West,Blender,1,59.00
';

(:~
 : Formats an amount.
 : @param  $amount  amount
 : @return formatted amount
 :)
declare function sr:amount(
  $amount  as xs:decimal
) as xs:string {
  format-number($amount, '#,##0.00')
};

let $csv := parse-csv($sr:CSV, { 'header': true() })
let $sales := (
  for $r in 1 to count($csv?rows)
  let $column := $csv?get($r, ?)
  return sr:sale(
    xs:date($column('date')),
    $column('region'),
    $column('product'),
    xs:integer($column('quantity')),
    xs:decimal($column('price'))
  )
)
let $months := $sales
  -> sort-by(., { 'key': fn { ?date } })
  -> partition(., fn($partition, $sale) { head($partition) =?> month() != $sale =?> month() })
let $totals := $months ! sum(?* =?> revenue())
let $cumulated := tail(scan($totals, 0, op('+')))
return <report total='{ sr:amount(sum($sales =?> revenue())) }'>
  <regions>{
    for $sale in $sales
    group by $region := $sale?region
    let $revenue := sum($sale =?> revenue())
    order by $revenue descending
    let $products := map:build($sale, fn { ?product }, fn { . =?> revenue() })
    let $product-revenue := fn($product) { sum($products?$product) }
    return <region name='{ $region }' revenue='{ sr:amount($revenue) }'
      best='{ highest(map:keys($products), (), $product-revenue) }'
      worst='{ lowest(map:keys($products), (), $product-revenue) }'/>
  }</regions>
  <months>{
    for $month at $m in $months
    return <month name='{ $month?1 =?> month() }'
      sales='{ array:size($month) }'
      revenue='{ sr:amount($totals[$m]) }'
      cumulated='{ sr:amount($cumulated[$m]?*) }'/>
  }</months>
  <top-sales>{
    for $sale in sort-by($sales, { 'key': fn { . =?> revenue() }, 'order': 'descending' })
    count $n
    while $n <= 3
    return <sale date='{ $sale?date }' region='{ $sale?region }' product='{ $sale?product }'
      revenue='{ sr:amount($sale =?> revenue()) }'/>
  }</top-sales>
</report>
