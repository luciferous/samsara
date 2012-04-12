# samsara [![Build Status](https://secure.travis-ci.org/luciferous/samsara.png?branch=master)](http://travis-ci.org/luciferous/samsara)

*To flow on, to perpetually wander, to pass through states of existence.*

```coffeescript
{ Cont , Proc , runProc } = require "samsara"

print = (x) -> -> console.log x
pause = Cont (_, r) -> setTimeout r, 1000

countDown = Proc( print 3 ).then( pause ).
            then( print 2 ).then( pause ).
            then( print 1 ).then( pause ).
            then( print "Lift off!" )

runProc countDown, ->
```

## Examples

- [Drag and drop](http://jsbin.com/etegid/56)

## Install

It's not necessary to install samsara to use it in a web browser, just link to
it with a `script` tag.

```html
<!doctype html>
<html>
  <head>
    <script src="//samsara-cdn.appspot.com/samsara.min.js"></script>
```

To use it as a Node module:

```sh
$ npm install samsara
```

## Contribute

```sh
$ git clone git://github.com/luciferous/samsara.git
$ cd samsara
$ npm install --dev
$ make dist
```

[browserify]: https://github.com/substack/node-browserify
[coffee-script]: https://github.com/jashkenas/coffee-script
