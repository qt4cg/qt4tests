xquery version "4.0";
module namespace set = "http://qt4cg.org/atomic-set";
   
   (:
      This package defines a type set:atomic-set which represents
      a set of distinct atomic items. Atomic items are considered
      distinct based on the comparison function fn:atomic-equal.
      
      An instance of an atomic set can be constructed using a function
      call such as set:build((1, 3, 5, 7, 9)).
      
      If $A and $B are instances of set:atomic-set, then they
      can be manipulated using methods including:
      
      $A =?> values() - returns the items in $A, as a sequence
      $A =?> size() - returns the number of items in the set
      $A =?> empty() - returns true if the set is empty
      $A =?> contains($k) - determines whether $k is a member of the set
      $A =?> contains-all($B) - returns true if $B is a subset of $A
      $A =?> add($k) - returns a new atomic set containing an additional item
      $A =?> remove($k) - returns a new atomic set in which the given item is absent
      $A =?> union($B) - returns a new atomic set holding the union of $A and $B
      $A =?> intersect($B) - returns a new atomic set holding the intersection of $A and $B
      $A =?> except($B) - returns a new atomic set holding the difference of $A and $B
      
      The set is constrained so it cannot contain the value NaN.
   :)
   
   declare %public record set:atomic-set (
       _data        as map(xs:anyAtomicType, xs:boolean),
       %static values := 
              fn($this as set:atomic-set) as xs:anyAtomicType* {
                map:keys($this?_data) 
              },
              
       %static size :=
              fn($this as set:atomic-set) as xs:integer { 
                map:size($this?_data) 
              },
              
       %static empty :=
              fn($this as set:atomic-set) as xs:boolean { 
                map:empty($this?_data) 
              },
              
       %static contains :=
              fn($this as set:atomic-set,
                 $value as xs:anyAtomicType) as xs:boolean { 
                map:contains($this?_data, $value) 
              },
              
       %static contains-all :=
              fn($this as set:atomic-set, 
                 $value as set:atomic-set) as xs:boolean {
                every($value =?> values(), 
                      map:contains($this?_data, ?)) 
              },
              
       %static add := 
              fn($this as set:atomic-set, 
                 $value as xs:anyAtomicType) as set:atomic-set {
                $this but with {'_data': map:put($this?_data, $value, true())} 
              },
              
       %static remove :=
              fn($this as set:atomic-set, 
                 $value as xs:anyAtomicType) as set:atomic-set {
                $this but with {'_data': map:remove($this?_data, $value)} 
              },
              
       %static union :=        
              fn($this as set:atomic-set, 
                 $other as set:atomic-set) as set:atomic-set {
                $this but with {'_data': map:merge(($this?_data, $other?_data),
                                                    {'duplicates': 'use-first'})
                               }
              },
              
       %static intersect :=        
              fn($this as set:atomic-set, 
                 $other as set:atomic-set) as set:atomic-set {
                $this but with {'_data': map:filter($this?_data, 
                                                    map:contains($other?_data, ?))
                               }
              },
              
       %static except :=        
              fn($this as set:atomic-set, 
                 $other as set:atomic-set) as set:atomic-set {
                $this but with {'_data': map:remove($this?_data, 
                                                    $other =?> values())
                               }
              }       
       
   ) where not(map:contains(?_data, number('NaN')));

   
   declare %public function set:of (
         $values as xs:anyAtomicType* := ()
       ) as set:atomic-set {
       
       set:atomic-set(
             map:build($values, 
                       value := true#0, 
                       options := {'duplicates': 'use-first'})
       )
   };