{ACache}  = require '../../index.js'

# -------------------------------------------------------------------------
# Starting in v2.0.0, constructor insists on both maxAgeMs and maxStorage
#  to prevent user error of passing one of them with a typo and inferring
#  Infinity. (Infinity must be explicitly requested now.)
# -------------------------------------------------------------------------

# -------------------------------------------------------------------------

exports.missing_options = (T, cb) ->
  try
    c = new ACache()
    caught = false
  catch e
    caught = true
  T.assert caught, "recognized missing options"
  cb()

# -------------------------------------------------------------------------

exports.missing_maxAgeMs = (T, cb) ->
  try
    # note it's supposed to be maxAgeMs, not max_age
    c = new ACache {max_age: 1000, maxStorage: 3}
    caught = false
  catch e
    caught = true
  T.assert caught, "recognized missing options"
  cb()

# -------------------------------------------------------------------------

exports.missing_maxStorage = (T, cb) ->
  try
    # note it's supposed to be maxStorage, not max_store
    c = new ACache {maxAgeMs: 1000, max_store: 3}
    caught = false
  catch e
    caught = true
  T.assert caught, "recognized missing options"
  cb()

# -------------------------------------------------------------------------

exports.infinities_ok = (T, cb) ->
  c = new ACache {maxAgeMs: Infinity, maxStorage: Infinity}
  T.assert c
  cb()

# -------------------------------------------------------------------------
