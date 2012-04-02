{ Proc
, arr
, first
, second
, split
, fanout
, fanin
, Right
, Left
, Tuple
, Thunk
, Cont
, runProc
} = require "./src/samsara"

foo = (x) -> x + 1
bar = (x) -> x * 3

console.log runProc Proc(foo).then(bar), 3
console.log runProc (first bar), 1, 2
console.log runProc (second bar), 1, 2
console.log runProc split(foo, bar), 1, 2
console.log runProc fanout(foo, bar), 1

constA = (x) -> (_) -> x

cons = (x, y) -> [x].concat(y)
listcase = (x) ->
  if x.length == 0 then Left()
  else Right Tuple [x[0], x[1..]]

mapA = (f) ->
  arr_ = arr(f)
  Proc( arr_ listcase ).
  then( fanin constA([])
      , Proc( split f, Thunk(mapA, [f]) ).
        then( arr_ cons ) )

console.log runProc (mapA bar), [1, 2, 3]

defer = []
later = (callback) -> defer.push callback

coo = Cont (x, r) -> later -> r [x * 5]
qoo = Cont (x, r) -> r [x, x]

zoo = Proc(bar).then(coo).then((x) -> x[0]).then(qoo)
runProc zoo, 4, -> console.log "results:", arguments...

joo = Proc(constA Left 5).then(fanin coo, qoo)
runProc joo, null, -> console.log "joo:", arguments...

setTimeout (-> x() for x in defer), 500
