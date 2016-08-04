# acache

```
npm install acache
```

Sometimes you want to:
  1. make an async call to get some data
  2. but use a cache if possible

Getting this right requires:
 * creating an LRU
 * a locking mechanism, so a bunch of concurrent cache misses for the same object don't cause extra work
 * turning inputs into a cache key
 * an easy uncaching call

This little lib makes it easy

Example


```coffeescript
ACache = require('acache').ACache

ac = new ACache {max_age_ms: 10000, max_storage: 100}

# say, get something from the database, given 2 uid's
ac.query {
  key_by: [uid, friend_uid] # cache using both of these
  fn: (cb) ->
    mysql.query 'SELECT BLEAH BLEAH WHERE SOMETHING=? AND SOMETHING=?', [uid, friend_uid], cb
}, defer err, rows, info

# remove something from the cache
ac.uncache {key_by: [uid, friend_uid]}
```

### constructor params:
 * `max_age_ms`: max time to store something in cache
 * `max_storage`: max answers to cache

### `query` params:
 * arg0 (object):
   * `key_by` : a key for this cache call. Feel free to pass an object or array; it will be hashed
   * `fn` : a function to run, to fill the cache, if it's missing. your function should take one parameter, `cb`. It should then call `cb` with `err, res1, res2,...`
 * arg1 (fn) :
   * a function you want called with `err, res1, res2, ...` from either the cache or hot read

## Errors

This does not cache errors.
