// Generated by IcedCoffeeScript 108.0.13
(function() {
  var ACache, LRU, LockTable, iced, util, __iced_k, __iced_k_noop;

  iced = require('iced-runtime');
  __iced_k = __iced_k_noop = function() {};

  LRU = require('kb-node-lru');

  LockTable = require('iced-lock').Table;

  util = require('util');

  ACache = (function() {
    function ACache(_arg) {
      var maxAgeMs, maxStorage, sizeFn;
      maxStorage = _arg.maxStorage, maxAgeMs = _arg.maxAgeMs, sizeFn = _arg.sizeFn;
      this._lru = new LRU({
        maxStorage: maxStorage,
        maxAgeMs: maxAgeMs,
        sizeFn: sizeFn
      });
      this._lock_table = new LockTable();
      this._counter = 0;
      this._hits = 0;
      this._misses = 0;
      this._puts = 0;
    }

    ACache.prototype.query = function(_arg, cb) {
      var did_hit, err, fn, keyBy, lock, msg, res, typ, ___iced_passed_deferral, __iced_deferrals, __iced_k;
      __iced_k = __iced_k_noop;
      ___iced_passed_deferral = iced.findDeferral(arguments);
      fn = _arg.fn, keyBy = _arg.keyBy;
      err = null;
      res = null;
      did_hit = false;
      typ = typeof keyBy;
      if (typ === 'object' || typ === 'function' || typ === 'undefined') {
        msg = "acache requires a scalar key. Got " + (util.inspect(keyBy));
        throw new Error(msg);
      }
      (function(_this) {
        return (function(__iced_k) {
          if (_this._counter++ % 100 === 0) {
            (function(__iced_k) {
              __iced_deferrals = new iced.Deferrals(__iced_k, {
                parent: ___iced_passed_deferral,
                filename: "/Users/max/src/iced/node-acache/index.iced",
                funcname: "ACache.query"
              });
              process.nextTick(__iced_deferrals.defer({
                lineno: 30
              }));
              __iced_deferrals._fulfill();
            })(__iced_k);
          } else {
            return __iced_k();
          }
        });
      })(this)((function(_this) {
        return function() {
          if (typeof (res = _this._lru.get(keyBy)) !== 'undefined') {
            _this._hits++;
            did_hit = true;
            return cb(null, res, did_hit);
          }
          (function(__iced_k) {
            __iced_deferrals = new iced.Deferrals(__iced_k, {
              parent: ___iced_passed_deferral,
              filename: "/Users/max/src/iced/node-acache/index.iced",
              funcname: "ACache.query"
            });
            _this._lock_table.acquire2({
              name: keyBy
            }, __iced_deferrals.defer({
              assign_fn: (function() {
                return function() {
                  return lock = arguments[0];
                };
              })(),
              lineno: 41
            }));
            __iced_deferrals._fulfill();
          })(function() {
            (function(__iced_k) {
              if (typeof (res = _this._lru.get(keyBy)) !== 'undefined') {
                _this._hits++;
                return __iced_k(did_hit = true);
              } else {
                _this._misses++;
                (function(__iced_k) {
                  __iced_deferrals = new iced.Deferrals(__iced_k, {
                    parent: ___iced_passed_deferral,
                    filename: "/Users/max/src/iced/node-acache/index.iced",
                    funcname: "ACache.query"
                  });
                  fn(__iced_deferrals.defer({
                    assign_fn: (function() {
                      return function() {
                        err = arguments[0];
                        return res = arguments[1];
                      };
                    })(),
                    lineno: 48
                  }));
                  __iced_deferrals._fulfill();
                })(function() {
                  return __iced_k(err == null ? _this._lru.put(keyBy, res) : void 0);
                });
              }
            })(function() {
              cb(err, res, did_hit);
              return lock.release();
            });
          });
        };
      })(this));
    };

    ACache.prototype.size = function() {
      return this._lru.size();
    };

    ACache.prototype.stats = function() {
      return {
        hits: this._hits,
        misses: this._misses,
        puts: this._puts,
        size: this.size()
      };
    };

    ACache.prototype.uncache = function(_arg) {
      var keyBy;
      keyBy = _arg.keyBy;
      return this._lru.remove(keyBy);
    };

    ACache.prototype.put = function(_arg, res) {
      var keyBy;
      keyBy = _arg.keyBy;
      this._lru.put(keyBy, res);
      return this._puts++;
    };

    ACache.prototype.peek = function(_arg) {
      var keyBy;
      keyBy = _arg.keyBy;
      return this._lru.get(keyBy);
    };

    return ACache;

  })();

  exports.ACache = ACache;

}).call(this);
