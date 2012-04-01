assert = require "assert"
{ arr, runProc, Proc } = require "samsara"

exports.testId = ->
  foo = ->
  assert.equal foo, arr(foo)(foo)
