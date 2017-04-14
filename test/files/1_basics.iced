{ACache}  = require '../../index.js'

async_arithmetic = ({a,b,delay}, cb) ->
  await setTimeout defer(), delay
  cb null, (a+b), (a-b)

_counter = 0
async_counter = (cb) ->
  await setTimeout defer(), 10
  cb ++_counter

exports.timing_check = (T, cb) ->
  c = new ACache {max_age_ms: 1000, max_storage: 3}
  arg = {a:1,b:2,delay:100}
  t1 = Date.now()
  await c.query {
    key_by: arg
    fn: (cb) -> async_arithmetic arg, cb
  }, defer err, sum, diff
  t2 = Date.now()
  T.assert (c.stats().misses is 1), 'cache miss count'
  T.assert (c.stats().hits is 0), 'cache hit count'
  T.assert (sum   is 3), 'sum ok'
  T.assert (diff is -1), 'diff ok'
  await c.query {
    key_by: arg
    fn: (cb) -> async_arithmetic arg, cb
  }, defer err, sum, diff
  t3 = Date.now()
  T.assert (sum   is 3), 'cached sum ok'
  T.assert (diff is -1), 'cached diff ok'

  # let's make sure second call was fast
  T.assert (t2 - t1 > 90), 'first call slow'
  T.assert (t3 - t2 < 10),  'second call fast'
  T.assert (c.stats().misses is 1), 'cache miss count'
  T.assert (c.stats().hits is 1), 'cache hit count'
  T.assert (c.size() is 1), 'cache size()'
  cb()

# -------

exports.expiration = (T, cb) ->
  c = new ACache {max_age_ms: 100, max_storage: 2}
  arg = {a:1,b:2,delay:200}
  t1 = Date.now()
  await c.query {
    key_by: arg
    fn: (cb) -> async_arithmetic arg, cb
  }, defer err, sum, diff
  t2 = Date.now()
  T.assert (sum   is 3), 'sum ok'
  T.assert (diff is -1), 'diff ok'
  await setTimeout defer(), 200
  await c.query {
    key_by: arg
    fn: (cb) -> async_arithmetic arg, cb
  }, defer err, sum, diff
  t3 = Date.now()
  T.assert (sum   is 3), 'cached sum ok'
  T.assert (diff is -1), 'cached diff ok'

  # let's make sure second call was fast
  T.assert (t2 - t1 > 90), 'first call slow'
  T.assert (t3 - t2 > 90),  'second call slow'

  T.assert (c.size() is 1), 'cache size()'

  cb()

# -------

exports.uncache = (T, cb) ->
  c = new ACache {max_age_ms: 1000, max_storage: 100}
  arg = {a:1,b:2,delay:100}
  t1 = Date.now()
  await c.query {
    key_by: arg
    fn: (cb) -> async_arithmetic arg, cb
  }, defer err, sum, diff
  t2 = Date.now()
  T.assert (sum   is 3), 'sum ok'
  T.assert (diff is -1), 'diff ok'
  c.uncache {key_by: arg}
  await c.query {
    key_by: arg
    fn: (cb) -> async_arithmetic arg, cb
  }, defer err, sum, diff
  t3 = Date.now()
  T.assert (sum   is 3), 'cached sum ok'
  T.assert (diff is -1), 'cached diff ok'

  # let's make sure second call was fast
  T.assert (t2 - t1 > 90), 'first call slow'
  T.assert (t3 - t2 > 90),  'second call slow'
  cb()

# -------

exports.locking = (T, cb) ->
  c = new ACache {max_age_ms: 100, max_storage: 2}
  await
    for i in [0...10]
      c.query {
        key_by: i # different keys so they can all run concurrently
        fn: (cb) -> async_counter (count) -> cb null, count
    }, defer err, count
  await async_counter defer count
  T.assert (count is 11), 'different keys, different locks'

  await
    for i in [0...10]
      c.query {
        key_by: 'shared' # same key so they will run one at a time, latter ones cached
        fn: (cb) -> async_counter (count) -> cb null, count
    }, defer err, count

  await async_counter defer count
  T.assert (count is 13), 'same key, same locks'
  cb()

# -------

exports.manual_put = (T, cb) ->
  c = new ACache {max_age_ms: 50, max_storage: 3}
  arg = {a:1,b:2,delay:100}
  c.put {key_by: arg}, 3, -1

  await c.query {
    key_by: arg
    fn: (cb) -> async_arithmetic arg, cb
  }, defer err, sum, diff
  t2 = Date.now()

  T.assert (c.size() is 1), 'cache size()'
  T.assert (c.stats().misses is 0), 'cache miss count'
  T.assert (c.stats().hits is 1), 'cache hit count'
  T.assert (c.stats().puts is 1), 'cache puts'
  T.assert (sum   is 3), 'sum ok'
  T.assert (diff is -1), 'diff ok'

  cb()




