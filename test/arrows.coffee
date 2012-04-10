assert = require "assert"
S = require "samsara"

###
 Minimal complete definition: arr and first, satisfying the laws
   arr id = id
   arr (f >>> g) = arr f >>> arr g
   first (arr f) = arr (first f)
   first (f >>> g) = first f >>> first g
   first f >>> arr fst = arr fst >>> f
   first f >>> arr (id *** g) = arr (id *** g) >>> first f
   first (first f) >>> arr assoc = arr assoc >>> first f
 where
   assoc ((a,b),c) = (a,(b,c))
###

arr = S.arr(->)

assoc = (ab, c) ->
  [a, b] = ab.items
  S.Tuple [a, S.Tuple [b, c]]

exports.testLaw1 = ->
  id = (a) -> a
  assert.equal id, arr(id)
  assert.equal 1, S.runProc(arr(id), 1)

exports.testLaw2 = ->
  f = (x) -> x * 3
  g = (x) -> x - 5
  a1 = arr S.compose(f, g)
  a2 = S.compose arr(f), arr(g)
  assert.equal 25, S.runProc(a1, 10)
  assert.equal 25, S.runProc(a2, 10)

exports.testLaw3 = ->
  f = arr (x) -> x * 9
  g = S.first arr(f)
  h = arr S.first(f)
  assert.deepEqual S.Tuple([27, 8]), S.runProc(g, 3, 8)
  assert.deepEqual S.Tuple([27, 8]), S.runProc(h, 3, 8)

exports.testLaw6 = ->
  id = arr (a) -> a
  f = arr (x) -> x * 3
  g = arr (x) -> x - 5
  a1 = S.Proc(S.first f).then(S.split id, g)
  a2 = S.Proc(S.split(id, g)).then(S.first f)
  assert.deepEqual S.runProc(a1, 10, 3), S.Tuple([30, -2])
  assert.deepEqual S.runProc(a2, 10, 3), S.Tuple([30, -2])

exports.testLaw7 = ->
  f = arr (x) -> x * 3
  a1 = S.Proc(S.first S.first(f)).then(arr assoc)
  a2 = S.Proc(arr assoc).then(S.first f)
  q = S.Tuple [S.Tuple([32, 2]), 2]
  r = S.Tuple [96, S.Tuple [2, 2]]
  assert.deepEqual r, S.runProc(a2, q)
  assert.deepEqual r, S.runProc(a1, q)
