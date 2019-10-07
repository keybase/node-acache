{ACache}  = require '../../index.js'

async_arithmetic = ({a,b,delay}, cb) ->
  await setTimeout defer(), delay
  cb null, {sum: (a+b), diff: (a-b)}

async_add = ({a,b,delay}, cb) ->
  await setTimeout defer(), delay
  cb null, a+b

_counter = 0
async_counter = (cb) ->
  await setTimeout defer(), 10
  cb ++_counter

exports.timing_check = (T, cb) ->
  c = new ACache {maxAgeMs: 1000, maxStorage: 3}
  arg = {a:1,b:2,delay:100}
  t1 = Date.now()
  await c.query {
    keyBy: arg
    fn: (cb) -> async_arithmetic arg, cb
  }, defer err, {sum, diff}, did_hit
  t2 = Date.now()
  T.assert (c.stats().misses is 1), 'cache miss count'
  T.assert (c.stats().hits is 0), 'cache hit count'
  T.assert (sum   is 3), 'sum ok'
  T.assert (diff is -1), 'diff ok'
  T.assert (not did_hit), 'missed cache'
  await c.query {
    keyBy: arg
    fn: (cb) -> async_arithmetic arg, cb
  }, defer err, {sum, diff}, did_hit
  t3 = Date.now()
  T.assert (sum   is 3), 'cached sum ok'
  T.assert (diff is -1), 'cached diff ok'
  T.assert did_hit, 'hit cache'

  T.assert c.peek({keyBy:arg})?, "peeked"
  T.assert not(c.peek({keyBy:"foo"})?), "peek failed"
  c.put { keyBy : "foo" }, "blah"
  T.assert c.peek({keyBy:"foo"})?, "peek worked"

  # let's make sure second call was fast
  T.assert (t2 - t1 > 90), 'first call slow'
  T.assert (t3 - t2 < 10),  'second call fast'
  T.assert (c.stats().misses is 1), 'cache miss count'
  T.assert (c.stats().hits is 1), 'cache hit count'
  T.assert (c.size() is 2), 'cache size()'
  cb()

# -------

exports.expiration = (T, cb) ->
  c = new ACache {maxAgeMs: 100, maxStorage: 2}
  arg = {a:1,b:2,delay:200}
  t1 = Date.now()
  await c.query {
    keyBy: arg
    fn: (cb) -> async_arithmetic arg, cb
  }, defer err, {sum, diff}
  t2 = Date.now()
  T.assert (sum   is 3), 'sum ok'
  T.assert (diff is -1), 'diff ok'
  await setTimeout defer(), 200
  await c.query {
    keyBy: arg
    fn: (cb) -> async_arithmetic arg, cb
  }, defer err, {sum, diff}
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
  c = new ACache {maxAgeMs: 1000, maxStorage: 100}
  arg = {a:1,b:2,delay:100}
  t1 = Date.now()
  await c.query {
    keyBy: arg
    fn: (cb) -> async_arithmetic arg, cb
  }, defer err, {sum, diff}
  t2 = Date.now()
  T.assert (sum   is 3), 'sum ok'
  T.assert (diff is -1), 'diff ok'
  c.uncache {keyBy: arg}
  await c.query {
    keyBy: arg
    fn: (cb) -> async_arithmetic arg, cb
  }, defer err, {sum, diff}
  t3 = Date.now()
  T.assert (sum   is 3), 'cached sum ok'
  T.assert (diff is -1), 'cached diff ok'

  # let's make sure second call was fast
  T.assert (t2 - t1 > 90), 'first call slow'
  T.assert (t3 - t2 > 90),  'second call slow'
  cb()

# -------

exports.locking = (T, cb) ->
  c = new ACache {maxAgeMs: 100, maxStorage: 2}
  await
    for i in [0...10]
      c.query {
        keyBy: i # different keys so they can all run concurrently
        fn: (cb) -> async_counter (count) -> cb null, count
    }, defer err, count
  await async_counter defer count
  T.assert (count is 11), 'different keys, different locks'

  await
    for i in [0...10]
      c.query {
        keyBy: 'shared' # same key so they will run one at a time, latter ones cached
        fn: (cb) -> async_counter (count) -> cb null, count
    }, defer err, count

  await async_counter defer count
  T.assert (count is 13), 'same key, same locks'
  cb()

# -------

exports.manual_put = (T, cb) ->
  c = new ACache {maxAgeMs: 50, maxStorage: 3}
  arg = {a:1,b:2,delay:100}
  c.put {keyBy: arg}, {sum: 3, diff: -1}

  await c.query {
    keyBy: arg
    fn: (cb) -> async_arithmetic arg, cb
  }, defer err, {sum, diff}, did_hit
  t2 = Date.now()

  T.assert did_hit, "hit after put"
  T.assert (c.size() is 1), 'cache size()'
  T.assert (c.stats().size is 1), 'cache stats().size'
  T.assert (c.stats().misses is 0), 'cache miss count'
  T.assert (c.stats().hits is 1), 'cache hit count'
  T.assert (c.stats().puts is 1), 'cache puts'
  T.assert (sum   is 3), 'sum ok'
  T.assert (diff is -1), 'diff ok'

  cb()

# -------

exports.no_cache_error = (T, cb) ->
  c = new ACache {maxAgeMs: 50, maxStorage: 3}
  arg = {a:1,b:2,delay:100}

  await c.query {
    keyBy: arg
    fn: (cb) -> cb new Error(), arg
  }, defer err, res

  t2 = Date.now()

  await c.query {
    keyBy: arg
    fn: (cb) -> cb new Error(), arg
  }, defer err, res

  T.assert (c.size() is 0), 'cache size()'
  T.assert (c.stats().size is 0), 'cache stats().size'
  T.assert (c.stats().misses is 2), 'cache miss count'
  T.assert (c.stats().hits is 0), 'cache hit count'
  T.assert (c.stats().puts is 0), 'cache puts'
  T.assert err?, 'error returned'

  cb()


# -------

exports.zero_answer_cached = (T, cb) ->
  c = new ACache {maxAgeMs: 50, maxStorage: 3}
  arg = {a:0,b:0,delay:100}

  await c.query {
    keyBy: arg
    fn: (cb) -> async_add arg, cb
  }, defer err, res
  T.assert (not err) and (res is 0), "got 0"

  t2 = Date.now()

  await c.query {
    keyBy: arg
    fn: (cb) -> async_add arg, cb
  }, defer err, res
  T.assert (not err) and (res is 0), "got 0"

  T.assert (c.size() is 1), 'cache size()'
  T.assert (c.stats().size is 1), 'cache stats().size'
  T.assert (c.stats().misses is 1), 'cache miss count'
  T.assert (c.stats().hits is 1), 'cache hit count'

  cb()




