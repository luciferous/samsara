{ protocol } = require "protocol/core"

class Tuple
  constructor: (@items=[]) ->
    return new Tuple @items unless this instanceof Tuple

tupled = (f) -> (t) ->
  if f instanceof Thunk then f = f.evaluate()
  f.apply null, if t instanceof Tuple then t.items else arguments

untuple = (t) -> if t instanceof Tuple then t.items else [t]

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
    if next instanceof Proc then next = next.target
    if @target.constructor == next.constructor
      Proc compose(@target, next)
    else if @target instanceof Function
      Proc leftComp(@target, next)
    else if next instanceof Function
      Proc rightComp(@target, next)
    else throw new TypeError "Unexpected #{next.constructor.name} type"

  apply: (ctx, args) ->
    @target.apply ctx, args

runProc = (proc, args...) ->
  proc.apply null, args

dot = (f, g) -> (x) -> f (g x)
swap = (x, y) -> Tuple [y, x]
dup = (x) -> Tuple [x, x]
id = (args...) -> if args.length == 1 then args[0] else Tuple args

leftComp = (f, a) ->
  compose arr(a)(f), a
rightComp = (a, f) ->
  compose a, arr(a)(f)

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
  first: (a) -> tupled (x, y) -> Tuple [a.apply(null, [x]), y]
  second: (a) -> Proc(swap).then(first a).then(swap)
  split: (a, b) -> Proc(first a).then(second b)
  fanout: (a, b) -> Proc(dup).then(split a, b)

Arrow Object, __Arrow

Arrow Function,
  arr: (p) -> (f) -> f
  first: (f) -> split f, id
  second: (f) -> split id, f
  split: (f, g) -> (x, y) ->
    if f instanceof Thunk then f = f.evaluate()
    if g instanceof Thunk then g = g.evaluate()
    Tuple [f.apply(null, untuple x), g.apply(null, untuple y)]

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
  arr: (p) -> (f) -> Cont (xs..., r) -> r f.apply(null, xs)
  compose: (f, g) -> Cont (xs..., r) ->
    r2 = (args...) -> g.apply null, args.concat(r)
    f.apply null, xs.concat(r2)

ArrowChoice Cont,
  left: (f) -> Cont (x, r) ->
    if x instanceof Left
      f.apply null, untuple(x.val).concat(dot r, Left)
    else r x

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
exports.Proc = Proc
exports.runProc = runProc

