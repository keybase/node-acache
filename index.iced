LRU         = require 'kb-node-lru'
LockTable   = require('iced-utils').lock.Table
util        = require('util')

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
    err        = null
    res        = null
    did_hit    = false

    typ = typeof keyBy
    if typ is 'object' or typ is 'function' or typ is 'undefined'
      msg = "acache requires a scalar key. Got #{util.inspect keyBy}"
      throw new Error(msg)

    # prevents stack max size exceeded when everything in cache and no IO needed
    if @_counter++ % 100 is 0
      await process.nextTick defer()

    # allow a quick exit if possible
    # where we don't even bother with the lock
    if typeof (res = @_lru.get keyBy) isnt 'undefined'
      @_hits++
      did_hit = true
      return cb null, res, did_hit

    # otherwise await the lock and check again,
    # and if still missing, we'll do the work
    await @_lock_table.acquire keyBy, defer(lock), true
    if typeof (res = @_lru.get keyBy) isnt 'undefined'
      @_hits++
      did_hit = true
    else
      @_misses++
      await fn defer err, res
      unless err?
        @_lru.put keyBy, res
    cb err, res, did_hit

    lock.release()

  ##----------------------------------------------------------------------

  size: -> @_lru.size()

  ##----------------------------------------------------------------------

  stats: -> {hits: @_hits, misses: @_misses, puts: @_puts, size: @size()}

  ##----------------------------------------------------------------------

  uncache: ({keyBy}) -> @_lru.remove keyBy

  ##----------------------------------------------------------------------

  put: ({keyBy}, res) ->
    # manually put something into the cache
    @_lru.put keyBy, res
    @_puts++

  ##----------------------------------------------------------------------

  peek : ({keyBy}) -> @_lru.get keyBy

  ##----------------------------------------------------------------------

# =============================================================================

exports.ACache = ACache
