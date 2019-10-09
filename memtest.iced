#
# to run this test run `make memtest`
#

{ACache} = require('./index')

INSERTS = 100 * 1000
STORAGE = 100 * 1000

print_usage = (ac, stage, ms, ops) =>
    perItem = process.memoryUsage().heapUsed / ac.size()
    heapUsedMb = process.memoryUsage().heapUsed / (1024 * 1024)
    heapTotalMb = process.memoryUsage().heapTotal / (1024 * 1024)
    opsPerMs = ops / ms
    console.log("#{ms}ms", "SIZE=#{ac.size()} per item=#{perItem.toFixed(1)} bytes ops/ms=#{opsPerMs.toFixed(0)}", stage, {
      heapUsedMb,
      heapTotalMb,
    })

query_test = (ac, note, cb) =>
  global.gc()
  d = Date.now()
  for i in [0...INSERTS]
    keyBy = "foobar1234#{i}"
    await ac.query {
      keyBy: keyBy
      fn: (cb) -> cb null, i + i
    }, defer err, ans, did_hit
  dt = Date.now() - d
  global.gc()
  print_usage(ac, note, dt, INSERTS)
  cb null

remove_test = (ac, note, cb) =>
  global.gc()
  d = Date.now()
  for i in [0...INSERTS]
    keyBy = "foobar1234#{i}"
    ac.uncache({keyBy})
  dt = Date.now() - d
  global.gc()
  print_usage(ac, note, dt, INSERTS)
  cb null

main = (_, cb)=>
  if not global.gc
    console.log 'Run this test with --expose-gc'
    process.exit 1
  ac = new ACache {maxAgeMs: Infinity, maxStorage: STORAGE}
  print_usage(ac, 'startup', 0, 0)

  while true
    await query_test ac, "cold", defer err
    await query_test ac, "hot", defer err
    await remove_test ac, "remove", defer err
  cb null

await main null, defer()
