{ACache}  = require '../../index.js'

# -------------------------------------------------------------------------
# Starting in v2.0.0, constructor insists on both max_age_ms and max_storage
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

exports.missing_max_age_ms = (T, cb) ->
  try
    # note it's supposed to be max_age_ms, not max_age
    c = new ACache {max_age: 1000, max_storage: 3}
    caught = false
  catch e
    caught = true
  T.assert caught, "recognized missing options"
  cb()

# -------------------------------------------------------------------------

exports.missing_max_storage = (T, cb) ->
  try
    # note it's supposed to be max_storage, not max_store
    c = new ACache {max_age_ms: 1000, max_store: 3}
    caught = false
  catch e
    caught = true
  T.assert caught, "recognized missing options"
  cb()

# -------------------------------------------------------------------------

exports.infinities_ok = (T, cb) ->
  c = new ACache {max_age_ms: Infinity, max_storage: Infinity}
  T.assert c
  cb()

# -------------------------------------------------------------------------
