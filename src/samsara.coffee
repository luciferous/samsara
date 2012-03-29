{ protocol } = require "protocol/core"

class Tuple
  constructor: (@items=[]) ->
    return new Tuple @items unless this instanceof Tuple

tupled = (f) -> (t) ->
  f.apply null, if t instanceof Tuple then t.items else arguments

class Thunk
  constructor: (@f, @xs=[]) ->
    return new Thunk @f, @xs unless this instanceof Thunk
  evaluate: -> @f.apply null, @xs

class Either
  constructor: (@val) ->

class Left extends Either
  constructor: (val) ->
    return new Left val unless this instanceof Left
    super val

class Right extends Either
  constructor: (val) ->
    return new Right val unless this instanceof Right
    super val

class Proc
  constructor: (@target) ->
    return new Proc @target unless this instanceof Proc
    if @target instanceof Proc
      @target = @target.target
  then: (next) ->
    if next instanceof Proc
      next = next.target
    if @target instanceof Function
      Proc compose(arr(next, @target), next)
    else if next instanceof Function
      Proc compose(@target, arr(@target, next))
    else
      Proc compose(@target, next)
  apply: (ctx, args) ->
    @target.apply ctx, args

runProc = (proc, args...) ->
  proc.apply null, args

dot = (f, g) -> (x) -> f (g x)
swap = (x, y) -> Tuple [y, x]
dup = (x) -> Tuple [x, x]
id = (x) -> x

Arrow = protocol
  arr: [protocol, "f"]
  compose: [protocol, "g"]
  first: [protocol]
  second: [protocol]
  split: [protocol, "b"]
  fanout: [protocol, "b"]

{ arr, compose, first, second, split, fanout } = Arrow

__Arrow =
  compose: (f, g) -> (xs...) -> tupled(g)(tupled(f).apply(null, xs))
  first: (a) -> tupled (x, y) -> Tuple [a.apply(null, [x]), y]
  second: (a) -> Proc(swap).then(first a).then(swap)
  split: (a, b) -> Proc(first a).then(second b)
  fanout: (a, b) -> Proc(dup).then(split a, b)

Arrow Object, __Arrow

Arrow Function,
  arr: (f, p) -> if p? then p else f
  first: (f) -> split f, id
  second: (f) -> split id, f
  split: (f, g) -> (x, y) ->
    if f instanceof Thunk then f = f.evaluate()
    if g instanceof Thunk then g = g.evaluate()
    Tuple [f.apply(null, [x]), g.apply(null, [y])]

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
  right: (f) -> Proc(mirror).then(left f).then(mirror)
  fork: (f, g) -> Proc(left f).then(right g)
  fanin: (f, g) -> Proc(fork f, g).then(untag)

ArrowChoice Object, __ArrowChoice

ArrowChoice Function,
  left: (f) -> fork f, id
  right: (f) -> fork id, f
  fork: (f, g) -> fanin dot(Left, f), dot(Right, g)
  fanin: (f, g) -> (x) ->
    z = ->
      if x instanceof Left then f
      else if x instanceof Right then g
      else throw TypeError "Expected Either type"
    tupled(z()).apply null, [x.val]

class Cont
  constructor: (@f) ->
    return new Cont @f if this not instanceof Cont
  apply: (ctx, args) ->
    [args..., r] = args
    if not (r.apply? and r.apply instanceof Function)
      throw TypeError "Expected function"
    @f.apply(null, args.concat [r])

Arrow Cont,
  arr: (p, f) -> Cont (xs..., r) -> r f.apply(null, xs)
  compose: (f, g) -> Cont (xs..., r) ->
    r2 = (args...) -> g.apply null, args.concat(r)
    f.apply null, xs.concat(r2)

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

exports.Cont = Cont

exports.Tuple = Tuple
exports.tupled = tupled
exports.Thunk = Thunk
exports.Left = Left
exports.Right = Right

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
    if x.length == 0 then Left()
    else Right Tuple [x[0], x[1..]]

  mapA = (f) ->
    Proc( arr listcase ).
    then( fanin constA([])
        , Proc( split f, Thunk(mapA, [f]) ).
          then( arr cons ) )

  console.log runProc (mapA bar), [1, 2, 3]

  defer = []
  later = (callback) -> defer.push callback

  coo = Cont (x, r) -> later -> r [x * 5]
  qoo = Cont (x, r) -> r [x, x]

  zoo = Proc(bar).then(coo).then((x) -> x[0]).then(qoo)
  runProc zoo, 4, -> console.log "results:", arguments...

  setTimeout (-> x() for x in defer), 500
