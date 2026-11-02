(:~
 : Build order: checks module dependencies and computes the order in which modules can be built.
 :
 : 4.0 features: fn:while-do, fn:transitive-closure, fn:duplicate-values,
 : fn:every, for member, focus functions.
 : @author Christian Gruen, BaseX
 :)
declare namespace bo = 'http://qt4cg.org/demos/build-order';

(:~ Build plan: waves of modules built so far, and modules ready for the next wave. :)
declare record bo:plan(
  waves  as array(xs:string+),
  ready  as xs:string*
);

(:~
 : Returns the names of the modules whose dependencies have all been built.
 : @param  $modules  modules
 : @param  $built    names of the modules that have been built
 : @return names
 :)
declare function bo:ready(
  $modules  as element(module)*,
  $built    as xs:string*
) as xs:string* {
  $modules[not(@name = $built)][every(uses, fn { . = $built })]/@name
};

(:~
 : Returns a sorted, space-separated list of distinct names.
 : @param  $names  names
 : @return list
 :)
declare function bo:list(
  $names  as xs:anyAtomicType*
) as xs:string {
  $names => distinct-values() => sort() => string-join(' ')
};

let $all := //module
let $modules := $all[not(@name = preceding-sibling::module/@name)]
let $names := $modules/@name
let $dependencies := fn($module as node()) as node()* {
  $modules[@name = $module/uses]
}
let $closures := map:build(
  $modules,
  fn { string(@name) },
  fn { transitive-closure(., $dependencies) }
)

(: the build plan: every wave contains the modules whose dependencies were built before :)
let $plan := while-do(
  bo:plan([], bo:ready($modules, ())),
  fn { exists(?ready) },
  fn($plan) {
    let $waves := array:append($plan?waves, $plan?ready)
    return bo:plan($waves, bo:ready($modules, $waves?*))
  }
)

return <build-plan>{
  for member $wave at $n in $plan?waves
  return <wave n='{ $n }'>{ bo:list($wave) }</wave>,

  <blocked>{ bo:list($names[not(. = $plan?waves?*)]) }</blocked>,
  <cycles>{ bo:list($modules[. intersect $closures?(string(@name))]/@name) }</cycles>,
  <unknown>{ bo:list($all/uses[not(. = $names)]) }</unknown>,
  <duplicates>{ bo:list(duplicate-values($all/@name)) }</duplicates>,

  for $name in sort(map:keys($closures))
  return <dependencies module='{ $name }'>{ bo:list($closures?$name/@name) }</dependencies>
}</build-plan>
