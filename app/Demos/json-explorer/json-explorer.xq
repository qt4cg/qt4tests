(:~
 : JSON explorer: navigates a package lock file with path expressions.
 :
 : 4.0 features: JNodes, fn:jkey, mapping arrows, for key/value.
 : @author Christian Gruen, BaseX
 :)
declare namespace je = 'http://qt4cg.org/demos/json-explorer';

(:~ Package lock file. :)
declare variable $je:LOCK := parse-json('{
  "name": "shop",
  "version": "1.0.0",
  "dependencies": { "express": "^4.19.0", "lodash": "^4.17.0", "left-pad": "^1.3.0" },
  "packages": {
    "express": {
      "version": "4.19.2", "license": "MIT",
      "dependencies": { "body-parser": "1.20.2", "debug": "2.6.9" }
    },
    "body-parser": {
      "version": "1.20.2", "license": "MIT",
      "dependencies": { "debug": "2.6.9", "qs": "6.11.0" }
    },
    "debug": {
      "version": "2.6.9", "license": "MIT",
      "dependencies": { "ms": "2.0.0" }
    },
    "ms": { "version": "2.0.0", "license": "MIT" },
    "qs": { "version": "6.11.0", "license": "BSD-3-Clause" },
    "lodash": { "version": "4.17.21", "license": "MIT" },
    "left-pad": {
      "version": "1.3.0", "license": "WTFPL",
      "deprecated": "use String.prototype.padStart()"
    },
    "chalk": {
      "version": "5.3.0", "license": "MIT",
      "dependencies": { "ansi-styles": "6.2.1" }
    },
    "ansi-styles": { "version": "6.2.1", "license": "MIT" }
  }
}');

(:~
 : Renders the dependency tree of a package.
 : @param  $name   package name
 : @param  $depth  nesting depth
 : @return lines
 :)
declare function je:tree(
  $name   as xs:string,
  $depth  as xs:integer
) as xs:string* {
  let $package := $je:LOCK/packages/$name
  return (
    `{ string-join(replicate('  ', $depth)) }{ $name } { $package/version }`,
    $package/dependencies/* =!> jkey() =!> je:tree($depth + 1)
  )
};

let $packages := $je:LOCK/packages/*
let $roots := $je:LOCK/dependencies
let $reachable := ($roots, transitive-closure($roots, fn($dependencies) {
  $packages[jkey() = $dependencies/* ! jkey()]/dependencies
}))/* ! jkey()
let $target := 'debug'
return (
  'Dependency tree:',
  $roots/* =!> jkey() =!> je:tree(1),

  'Licenses:',
  for $package in $packages
  group by $license := string($package/license)
  order by $license
  return `  { $license }: { sort($package ! jkey()) => string-join(', ') }`,

  `Dependents of { $target }:`,
  for $dependency in $je:LOCK//dependencies/$target
  return `  { $dependency/../.. ! jkey() otherwise $je:LOCK?name } requires { $dependency }`,

  'Deprecated:',
  for key $name value $package in $je:LOCK?packages
  where exists($package?deprecated)
  return `  { $name }: { $package?deprecated }`,

  'Unused:',
  $packages[not(jkey() = $reachable)] ! `  { jkey() }`
)
