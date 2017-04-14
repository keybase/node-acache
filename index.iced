LRU         = require 'kb-node-lru'
LockTable   = require('iced-utils').lock.Table
crypto      = require 'crypto'
hash        = require 'object-hash'

# -------------------------------------------------------------------------

CONFIG =
  HASH_LEN: 20
  MAX_STRING_AS_KEY: 60

# -------------------------------------------------------------------------

class ACache

  constructor: ({max_storage, max_age_ms, size_fn}) ->
    @_lru        = new LRU {max_storage, max_age_ms}
    @_lock_table = new LockTable()
    @_counter    = 0
    @_hits       = 0
    @_misses     = 0
    @_puts       = 0

  ##----------------------------------------------------------------------

  query: ({fn, key_by}, cb) ->
    ckey       = @_cacheKey key_by
    err        = null
    res_array  = null
    await @_lock_table.acquire ckey, defer(lock), true
    if @_counter++ % 100 is 0 # faster than doing it every time
      await process.nextTick defer()
    if (res_array = @_lru.get ckey)
      @_hits++
    else
      @_misses++
      await fn defer err, res_array...
      unless err?
        @_lru.put ckey, res_array
    cb err, res_array... # call back with args separated
    lock.release()

  ##----------------------------------------------------------------------

  size: -> @_lru.size()

  ##----------------------------------------------------------------------

  stats: -> {hits: @_hits, misses: @_misses, puts: @_puts}

  ##----------------------------------------------------------------------

  uncache: ({key_by}) -> @_lru.remove @_cacheKey key_by

  ##----------------------------------------------------------------------

  put: ({key_by}, res_array...) ->
    # manually put something into the cache
    @_lru.put @_cacheKey(key_by), res_array
    @_puts++

  ##----------------------------------------------------------------------

  _cacheKey: (o) ->
    # for strings we'd rather not hash which ends up being expensive
    if (typeof(o) is 'string') and o.length <= CONFIG.MAX_STRING_AS_KEY then return o
    if (typeof(o) is 'number') then return o
    return hash(o,{encoding:'base64'})[...CONFIG.HASH_LEN]

# =============================================================================

exports.ACache = ACache
