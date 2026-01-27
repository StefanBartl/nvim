# Autocmds Baseline

**Timestamp:** 2026-01-27 21:10:00
**Status:** ✅ PASSED

## Summary

- **total_events:** 0
- **duration_ms:** 5243.62
- **report_file:** C:\Users\bartl\AppData\Local\nvim-data/bench_reports/baseline_20260127_211000.md


   Info  21:09:55 notify.info [benchmarks] 🚀 Running benchmark: Autocmds Baseline
   Info  21:10:00 notify.info [benchmarks] 📄 Report saved: C:\Users\bartl\AppData\Local\nvim/docs/BENCHMARKS/reports/autocmds_baseline_20260127_211000.md
   Info  21:10:00 notify.info [benchmarks] ✅ Autocmds Baseline

# Autocmds Baseline

**Timestamp:** 2026-01-27 21:10:00
**Status:** ✅ PASSED

## Summary

- **total_events:** 0
- **duration_ms:** 5243.62
- **report_file:** C:\Users\bartl\AppData\Local\nvim-data/bench_reports/baseline_20260127_211000.md

21:10:00 msg_show.lua_print   BenchAutocmdsBaseline 🚀 Starting baseline benchmark suite...
21:10:00 msg_show.lua_print   BenchAutocmdsBaseline This will take ~2-3 minutes...
21:10:00 msg_show.lua_print   BenchAutocmdsBaseline [1/6] Benchmarking CursorMoved (CRITICAL)...
21:10:00 msg_show.lua_print   BenchAutocmdsBaseline   ✓ Avg: 0.090ms | Min: 0.081ms | Max: 0.432ms
21:10:00 msg_show.lua_print   BenchAutocmdsBaseline [2/6] Benchmarking BufEnter (HIGH)...
21:10:00 msg_show.lua_print   BenchAutocmdsBaseline   ✓ Avg: 0.471ms | Min: 0.401ms | Max: 0.929ms
21:10:00 msg_show.lua_print   BenchAutocmdsBaseline [3/6] Benchmarking BufWinEnter (HIGH)...
21:10:00 msg_show.lua_print   BenchAutocmdsBaseline   ✓ Avg: 0.155ms | Min: 0.125ms | Max: 0.345ms
21:10:00 msg_show.lua_print   BenchAutocmdsBaseline [4/6] Benchmarking BufWritePre (MEDIUM)...
21:10:00 msg_show.lua_print   BenchAutocmdsBaseline   ✓ Avg: 1.699ms | Min: 1.537ms | Max: 2.408ms
21:10:00 msg_show.lua_print   BenchAutocmdsBaseline [5/6] Benchmarking FileType (MEDIUM)...
21:10:00 msg_show.lua_print   BenchAutocmdsBaseline   ✓ Avg: 16.922ms | Min: 15.545ms | Max: 22.025ms
21:10:00 msg_show.lua_print   BenchAutocmdsBaseline [6/6] Benchmarking ColorScheme (LOW)...
21:10:00 msg_show.lua_print   BenchAutocmdsBaseline   ✓ Avg: 3.489ms | Min: 2.787ms | Max: 6.792ms
21:10:00 msg_show.lua_print   BenchAutocmdsBaseline 📊 Generating report...
21:10:00 msg_show.lua_print   BenchAutocmdsBaseline ✅ Report saved to: C:\Users\bartl\AppData\Local\nvim-data/bench_reports/baseline_20260127_211000.md
21:10:00 msg_show.lua_print   BenchAutocmdsBaseline Summary:
21:10:00 msg_show.lua_print   BenchAutocmdsBaseline # Autocmd Baseline Performance Report

**Timestamp:** 2026-01-27 21:10:00
**Neovim Version:** 0.11.0
**System:** Windows_NT x86_64

## Results

| Event                | Iterations | Total (ms) | Avg (ms) | Min (ms) | Max (ms) | StdDev (ms) |
|----------------------|------------|------------|----------|----------|----------|-------------|
| CursorMoved          |   1000 |   90.402 |    0.090 |    0.081 |    0.432 |    0.020 |
| BufEnter             |    500 |  235.685 |    0.471 |    0.401 |    0.929 |    0.073 |
| BufWinEnter          |    500 |   77.364 |    0.155 |    0.125 |    0.345 |    0.033 |
| BufWritePre          |    200 |  339.736 |    1.699 |    1.537 |    2.408 |    0.156 |
| FileType             |    200 | 3384.346 |   16.922 |   15.545 |   22.025 |    0.910 |
| ColorScheme          |    100 |  348.943 |    3.489 |    2.787 |    6.792 |    0.679 |

## Raw Data (CSV)

```csv
event,iterations,total_ms,avg_ms,min_ms,max_ms,stddev_ms,timestamp
CursorMoved,1000,90.401900,0.090402,0.080500,0.431500,0.019575,2026-01-27 21:09:55
BufEnter,500,235.684700,0.471369,0.401100,0.929000,0.072875,2026-01-27 21:09:55
BufWinEnter,500,77.363600,0.154727,0.125100,0.344700,0.032559,2026-01-27 21:09:55
BufWritePre,200,339.735500,1.698678,1.537000,2.408300,0.155968,2026-01-27 21:09:56
FileType,200,3384.346300,16.921732,15.544600,22.024900,0.910163,2026-01-27 21:09:59
ColorScheme,100,348.942700,3.489427,2.786500,6.792200,0.679281,2026-01-27 21:10:00
```
^
