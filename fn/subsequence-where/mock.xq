(:*******************************************************:)
(: Test: mock.xq                                         :)
(: Written By: Michael Kay                               :)
(: Date: 2024-02-13                                      :)
(: Purpose: A function supposedly equivalent to          :) 
(:          subsequence-where                            :)
(:*******************************************************:)

module namespace mock="http://www.w3.org/QT3/subsequence-where/mock";

declare function mock:subsequence-where (
  $input	as item()*,	
  $from	as (function(item(), xs:integer) as xs:boolean)?	:= true#0,
  $to	as (function(item(), xs:integer) as xs:boolean)?	:= false#0
) as item()*
{
   let $start := trace(index-where($input, $from)[1] 
              otherwise (count($input) + 1), '$start')
   let $end :=   trace(index-where($input, $to)[. ge $start][1] 
              otherwise (count($input) + 1), '$end')
   return slice($input, $start, $end)
};
