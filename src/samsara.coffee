{ protocol } = require "protocol/core"

class Tuple
  constructor: (@items) ->

tuple = (items...) -> new Tuple items
tupled = (f) -> (t) ->
  f.apply null, if t instanceof Tuple then t.items else arguments

class Thunk
  constructor: (@f, @xs=[]) ->
  evaluate: -> @f.apply null, @xs

thunk = (f, args=[]) -> new Thunk f, args

class Either
  constructor: (@val) ->

class Left extends Either
class Right extends Either

makeLeft = (x) -> new Left x
makeRight = (x) -> new Right x

class Proc
  constructor: (@target) ->
    return new Proc @target unless this instanceof Proc
    if @target instanceof Proc
      @target = @target.target
  then: (next) ->
    if next instanceof Proc
      next = next.target
    Proc compose(@target, next)
  apply: (ctx, args) ->
    @target.apply ctx, args

runProc = (proc, args...) ->
  proc.apply null, args

dot = (f, g) -> (x) -> f (g x)
swap = (x, y) -> tuple y, x
dup = (x) -> tuple x, x
id = (x) -> x

Arrow = protocol
  arr: [protocol]
  compose: [protocol, "g"]
  first: [protocol]
  second: [protocol]
  split: [protocol, "b"]
  fanout: [protocol, "b"]

{ arr, compose, first, second, split, fanout } = Arrow

__Arrow =
  compose: (f, g) -> (xs...) -> tupled(g)(tupled(f).apply(null, xs))
  first: (a) -> tupled (x, y) -> tuple (a.apply null, [x]), y
  second: (a) -> Proc(arr swap).then(first a).then(arr swap)
  split: (a, b) -> Proc(first a).then(second b)
  fanout: (a, b) -> Proc(arr dup).then(split a, b)

Arrow Object, __Arrow

Arrow Function,
  arr: (f) -> f
  first: (f) -> split f, id
  second: (f) -> split id, f
  split: (f, g) -> (x, y) ->
    if f instanceof Thunk then f = f.evaluate()
    if g instanceof Thunk then g = g.evaluate()
    tuple f.apply(null, [x]), g.apply(null, [y])

ArrowChoice = protocol
  left: [protocol]
  right: [protocol]
  fork: [protocol, "b"]
  fanin: [protocol, "b"]

{ left, right, fork, fanin } = ArrowChoice

mirror = (x) ->
  if x instanceof Left then new Right x.val
  else if x instanceof Right then new Left x.val
untag = (x) ->
  throw TypeError "Expected instance of Either" if x not instanceof Either
  x.val

__ArrowChoice =
  right: (f) -> Proc(arr mirror).then(left f).then(arr mirror)
  fork: (f, g) -> Proc(left f).then(right g)
  fanin: (f, g) -> Proc(fork f, g).then(arr untag)

ArrowChoice Object, __ArrowChoice

ArrowChoice Function,
  left: (f) -> fork f, id
  right: (f) -> fork id, f
  fork: (f, g) -> fanin dot(makeLeft, f), dot(makeRight, g)
  fanin: (f, g) -> (x) ->
    z = ->
      if x instanceof Left then f
      else if x instanceof Right then g
      else throw TypeError "Expected Either type"
    tupled(z()).apply null, [x.val]

exports.arr = arr
exports.compose = compose
exports.first = first
exports.second = second
exports.split = split
exports.fanout = fanout

exports.left = left
exports.right = right
exports.fork = fork
exports.fanin = fanin

if require.main == module
  assert = require "assert"

  foo = (x) -> x + 1
  bar = (x) -> x * 3

  assert.equal foo, (arr foo)

  console.log runProc Proc(foo).then(bar), 3
  console.log runProc (first bar), 1, 2
  console.log runProc (second bar), 1, 2
  console.log runProc split(foo, bar), 1, 2
  console.log runProc fanout(foo, bar), 1

  constA = arr (x) -> (_) -> x

  cons = (x, y) -> [x].concat(y)
  listcase = (x) ->
    if x.length == 0 then makeLeft()
    else makeRight tuple(x[0], x[1..])

  mapA = (f) ->
    Proc( arr listcase ).
    then( fanin constA([])
        , Proc( split f, thunk(mapA, [f]) ).
          then( arr cons ) )

  console.log runProc (mapA bar), [1, 2, 3]
