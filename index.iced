LRU         = require 'kb-node-lru'
LockTable   = require('iced-utils').lock.Table
crypto      = require 'crypto'
hash        = require 'object-hash'

class ACache

  ##----------------------------------------------------------------------
  # a simple class for async reqs with caching the result in an LRU
  #   - uses a per-key lock to only allow one call for a certain entry
  #   - does not cache errors (can add this as option later, if wanted)
  ##----------------------------------------------------------------------

  constructor: ({max_storage, max_age_ms, size_fn}) ->
    @_lru        = new LRU {max_storage, max_age_ms}
    @_lock_table = new LockTable()
    @_counter    = 0

  ##----------------------------------------------------------------------

  query: ({fn, key_by}, cb) ->
    ckey       = @_cache_key key_by
    err        = null
    res_array  = null
    await @_lock_table.acquire ckey, defer(lock), true
    if (res_array = @_lru.get ckey)
      await process.nextTick defer()
    else
      await fn defer err, res_array...
      unless err?
        @_lru.put ckey, res_array
    cb err, res_array... # call back with args separated
    lock.release()

  ##----------------------------------------------------------------------

  uncache: ({key_by}) -> @_lru.remove @_cache_key key_by

  ##----------------------------------------------------------------------

  get_lru: ({key_by}) -> @_lru.remove @_cache_key key_by

  ##----------------------------------------------------------------------

  _cache_key: (o) -> hash(o,{encoding:'base64'})[...14]

# =============================================================================

exports.ACache = ACache
