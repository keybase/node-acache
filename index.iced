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

  constructor: ({maxStorage, maxAgeMs, sizeFn}) ->
    @_lru        = new LRU {maxStorage: maxStorage, maxAgeMs: maxAgeMs, sizeFn: sizeFn}
    @_lock_table = new LockTable()
    @_counter    = 0
    @_hits       = 0
    @_misses     = 0
    @_puts       = 0

  ##----------------------------------------------------------------------

  query: ({fn, keyBy}, cb) ->
    ckey       = @_cacheKey keyBy
    err        = null
    res        = null
    did_hit    = false
    await @_lock_table.acquire ckey, defer(lock), true
    if @_counter++ % 100 is 0 # faster than doing it every time
      await process.nextTick defer()
    if typeof (res = @_lru.get ckey) isnt 'undefined'
      @_hits++
      did_hit = true
    else
      @_misses++
      await fn defer err, res
      unless err?
        @_lru.put ckey, res
    cb err, res, did_hit

    lock.release()

  ##----------------------------------------------------------------------

  size: -> @_lru.size()

  ##----------------------------------------------------------------------

  stats: -> {hits: @_hits, misses: @_misses, puts: @_puts, size: @size()}

  ##----------------------------------------------------------------------

  uncache: ({keyBy}) -> @_lru.remove @_cacheKey keyBy

  ##----------------------------------------------------------------------

  put: ({keyBy}, res) ->
    # manually put something into the cache
    @_lru.put @_cacheKey(keyBy), res
    @_puts++

  ##----------------------------------------------------------------------

  peek : ({keyBy}) ->
    @_lru.get @_cacheKey(keyBy)

  ##----------------------------------------------------------------------

  _cacheKey: (o) ->
    # for strings we'd rather not hash which ends up being expensive
    if (typeof(o) is 'string') and o.length <= CONFIG.MAX_STRING_AS_KEY then return o
    if (typeof(o) is 'number') then return o
    return hash(o,{encoding:'base64'})[...CONFIG.HASH_LEN]

# =============================================================================

exports.ACache = ACache
