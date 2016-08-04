# kb-node-lru
Simple Async Caching Calls

Sometimes you want to:
  1. make an async call to get some data
  2. but cache the result

Getting this right requires:
 * creating an LRU
 * a locking mechanism, so a bunch of concurrent cache misses for the same object don't cause extra work
 * turning inputs into a cache key

This little lib makes it easy

Example

```
npm install acache
```


```coffeescript
ACache = require('acache').ACache

ac = new ACache {max_age_ms: 10000, max_storage: 100}
uid = '1234'

# get something from the database
ac.query {
  key_by: [uid, friend_uid]
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
