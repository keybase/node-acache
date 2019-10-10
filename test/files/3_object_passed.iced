{ACache}  = require '../../index.js'

# -------------------------------------------------------------------------

exports.got_null = (T, cb) ->
  c = new ACache {maxAgeMs: 50, maxStorage: 3}
  caught_err = false
  try
    c.query {
      keyBy: null
      fn: (cb) -> cb null, true
    }, (err, res, did_hit) =>
  catch err
    caught_err = true
    console.error(err.message)
  T.assert caught_err, "got err on null keyBy"
  cb()


# -------------------------------------------------------------------------

exports.got_array = (T, cb) ->
  c = new ACache {maxAgeMs: 50, maxStorage: 3}
  caught_err = false
  try
    c.query {
      keyBy: []
      fn: (cb) -> cb null, true
    }, (err, res, did_hit) =>
  catch err
    caught_err = true
    console.error(err.message)
  T.assert caught_err, "got err on array keyBy"
  cb()

# -------------------------------------------------------------------------

exports.got_undefined = (T, cb) ->
  c = new ACache {maxAgeMs: 50, maxStorage: 3}
  caught_err = false
  try
    c.query {
      keyBy: undefined
      fn: (cb) -> cb null, true
    }, (err, res, did_hit) =>
  catch err
    caught_err = true
    console.error(err.message)
  T.assert caught_err, "got err on undefined keyBy"
  cb()

# -------------------------------------------------------------------------

exports.got_function = (T, cb) ->
  c = new ACache {maxAgeMs: 50, maxStorage: 3}
  caught_err = false
  try
    c.query {
      keyBy: () => 123
      fn: (cb) -> cb null, true
    }, (err, res, did_hit) =>
  catch err
    caught_err = true
    console.error(err.message)
  T.assert caught_err, "got err on function keyBy"
  cb()

# -------------------------------------------------------------------------

exports.got_obj = (T, cb) ->
  c = new ACache {maxAgeMs: 50, maxStorage: 3}
  caught_err = false
  try
    c.query {
      keyBy: {foo: "bar"}
      fn: (cb) -> cb null, true
    }, (err, res, did_hit) =>
  catch err
    caught_err = true
    console.error(err.message)
  T.assert caught_err, "got err on object keyBy"
  cb()


