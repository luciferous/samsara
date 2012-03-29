# samsara [![Build Status](https://secure.travis-ci.org/luciferous/samsara.png?branch=v2)](http://travis-ci.org/luciferous/samsara)

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

## Install

```sh
$ npm install samsara
```
