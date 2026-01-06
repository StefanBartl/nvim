#!/usr/bin/env zsh
#
# Automated Neovim startup benchmarking with statistics and memory tracking
#
# Usage:
#   ./benchmark_nvim.sh [runs] [--skip-warmup] [--debug]
#
# Examples:
#   ./benchmark_nvim.sh 20
#   ./benchmark_nvim.sh 10 --skip-warmup
#   ./benchmark_nvim.sh 5 --debug

# Configuration
RUNS=15
NVIM_EXE="nvim"
SKIP_WARMUP=0
DEBUG=0
TIMEOUT=5

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Parse arguments
for arg in "$@"; do
    case $arg in
        --skip-warmup)
            SKIP_WARMUP=1
            shift
            ;;
        --debug)
            DEBUG=1
            shift
            ;;
        [0-9]*)
            RUNS=$arg
            shift
            ;;
    esac
done

# Determine script directory
SCRIPT_DIR="${0:A:h}"
LUA_SCRIPT="$SCRIPT_DIR/benchmark_startup.lua"

# Check if Lua script exists
if [[ ! -f "$LUA_SCRIPT" ]]; then
    echo "${RED}Error: Benchmark script not found: $LUA_SCRIPT${NC}" >&2
    exit 1
fi

# Check if nvim is available
if ! command -v "$NVIM_EXE" &> /dev/null; then
    echo "${RED}Error: Neovim not found in PATH${NC}" >&2
    exit 1
fi

# Use paths from environment (set by init.lua) or determine from config
if [[ -n "$NVIM_BENCHMARK_RESULTS_DIR" ]]; then
    results_dir="$NVIM_BENCHMARK_RESULTS_DIR"
else
    # Determine config directory
    if [[ -n "$XDG_CONFIG_HOME" ]]; then
        config_dir="$XDG_CONFIG_HOME/nvim"
    else
        config_dir="$HOME/.config/nvim"
    fi
    results_dir="$config_dir/lua/debugging/performance/results"
fi

if [[ -n "$NVIM_BENCHMARK_CSV_DIR" ]]; then
    csv_dir="$NVIM_BENCHMARK_CSV_DIR"
else
    csv_dir="$results_dir/csv"
fi

if [[ -n "$NVIM_BENCHMARK_HTML_DIR" ]]; then
    html_dir="$NVIM_BENCHMARK_HTML_DIR"
else
    html_dir="$results_dir/html"
fi

# Create directories
mkdir -p "$results_dir" "$csv_dir" "$html_dir"

echo "${CYAN}Using paths:${NC}"
echo "${GRAY}  Results: $results_dir${NC}"
echo "${GRAY}  CSV:     $csv_dir${NC}"
echo "${GRAY}  HTML:    $html_dir${NC}"
echo ""

# Storage arrays
startup_times=()
ui_enter_times=()
memory_usages=()
plugin_counts=()
all_slow_plugins=()

# Warmup run (unless skipped)
if ((SKIP_WARMUP == 0)); then
    echo "${CYAN}Running warmup...${NC}"

    warmup_file="/tmp/nvim_startuptime_warmup_$$.txt"
    export NVIM_STARTUPTIME_FILE="$warmup_file"

    timeout ${TIMEOUT}s "$NVIM_EXE" --headless --startuptime "$warmup_file" \
        -c "luafile $LUA_SCRIPT" > /dev/null 2>&1 || true

    sleep 0.5
    echo "${GREEN}Warmup complete${NC}"
    echo ""
fi

echo "${CYAN}Starting $RUNS benchmark runs...${NC}"
echo ""

# Run benchmarks
for i in {1..$RUNS}; do
    printf "Run %d/%d... " "$i" "$RUNS"

    # Create temp file for startuptime
    startupfile="/tmp/nvim_startuptime_${i}_$$.txt"
    export NVIM_STARTUPTIME_FILE="$startupfile"

    # Run Neovim with timeout and capture output
    if ((DEBUG == 1)); then
        echo ""
        echo "${MAGENTA}DEBUG: Running nvim...${NC}"
    fi

    output=$(timeout ${TIMEOUT}s "$NVIM_EXE" --headless --startuptime "$startupfile" \
        -c "luafile $LUA_SCRIPT" 2>&1)
    exit_code=$?

    if ((DEBUG == 1)); then
        echo "${MAGENTA}DEBUG OUTPUT:${NC}"
        echo "$output" | while IFS= read -r line; do
            echo "${GRAY}  $line${NC}"
        done
        echo ""
    fi

    # Check for timeout
    if [[ $exit_code -eq 124 ]]; then
        echo "${RED}TIMEOUT - killed after ${TIMEOUT}s${NC}"
        continue
    fi

    # Look for the timing line: startup,ui_enter,memory,plugin_count,[...]
    timing_line=$(echo "$output" | grep -E '^\d+\.\d+,\d+\.\d+,\d+\.\d+,\d+,' | head -n1)

    if [[ "$timing_line" =~ ^([0-9.]+),([0-9.]+),([0-9.]+),([0-9]+),(.*)$ ]]; then
        startup="${match[1]}"
        ui_enter="${match[2]}"
        memory="${match[3]}"
        plugin_count="${match[4]}"
        slow_json="${match[5]}"

        startup_times+=($startup)
        ui_enter_times+=($ui_enter)
        memory_usages+=($memory)
        plugin_counts+=($plugin_count)

        # Try to parse slow plugins JSON
        if [[ -n "$slow_json" ]] && [[ "$slow_json" != "[]" ]]; then
            all_slow_plugins+=("$slow_json")
        fi

        echo "${GREEN}Startup=${startup}ms UI=${ui_enter}ms Memory=${memory}KB Plugins=${plugin_count}${NC}"
    else
        echo "${RED}FAILED (no valid output)${NC}"
        if ((DEBUG == 0)); then
            echo "${YELLOW}  Tip: Run with --debug to see Neovim output${NC}"
        fi
    fi

    # Small delay between runs
    sleep 0.3
done

echo ""

# Check if we have data
if ((${#startup_times[@]} == 0)); then
    echo "${RED}No successful measurements!${NC}"
    echo "${YELLOW}Try running with --debug flag to see what's happening${NC}"
    exit 1
fi

echo "${CYAN}=== Results ===${NC}"
echo ""

# Calculate statistics
calculate_stats() {
    local data=("$@")
    local count=${#data[@]}

    if ((count == 0)); then
        echo "0 0 0 0 0"
        return
    fi

    # Sort array
    local sorted=(${(on)data})

    # Sum
    local sum=0
    for val in "${sorted[@]}"; do
        sum=$(echo "$sum + $val" | bc -l)
    done

    # Mean
    local mean=$(echo "scale=2; $sum / $count" | bc -l)

    # Median
    local median
    if ((count % 2 == 1)); then
        median=${sorted[$(((count + 1) / 2))]}
    else
        local mid1=${sorted[$((count / 2))]}
        local mid2=${sorted[$((count / 2 + 1))]}
        median=$(echo "scale=2; ($mid1 + $mid2) / 2" | bc -l)
    fi

    # Min/Max
    local min=${sorted[1]}
    local max=${sorted[-1]}

    # Standard deviation
    local variance=0
    for val in "${sorted[@]}"; do
        local diff=$(echo "$val - $mean" | bc -l)
        local sq=$(echo "$diff * $diff" | bc -l)
        variance=$(echo "$variance + $sq" | bc -l)
    done
    variance=$(echo "scale=6; $variance / $count" | bc -l)
    local stddev=$(echo "scale=2; sqrt($variance)" | bc -l)

    # Format output
    printf "%.2f %.2f %.2f %.2f %.2f" \
           "$mean" "$median" "$min" "$max" "$stddev"
}

# Calculate stats for all metrics
read -r startup_mean startup_median startup_min startup_max startup_stddev <<< \
    $(calculate_stats "${startup_times[@]}")

read -r ui_mean ui_median ui_min ui_max ui_stddev <<< \
    $(calculate_stats "${ui_enter_times[@]}")

read -r mem_mean mem_median mem_min mem_max mem_stddev <<< \
    $(calculate_stats "${memory_usages[@]}")

echo "${YELLOW}Startup Time (ms):${NC}"
echo "  Mean:   $startup_mean"
echo "  Median: $startup_median"
echo "  Min:    $startup_min"
echo "  Max:    $startup_max"
echo "  StdDev: $startup_stddev"

echo ""
echo "${YELLOW}UI Enter Time (ms):${NC}"
echo "  Mean:   $ui_mean"
echo "  Median: $ui_median"
echo "  Min:    $ui_min"
echo "  Max:    $ui_max"
echo "  StdDev: $ui_stddev"

echo ""
echo "${YELLOW}Memory Usage (KB):${NC}"
echo "  Mean:   $mem_mean"
echo "  Median: $mem_median"
echo "  Min:    $mem_min"
echo "  Max:    $mem_max"
echo "  StdDev: $mem_stddev"

echo ""
echo "${CYAN}=== Raw Data ===${NC}"
for i in {1..${#startup_times[@]}}; do
    printf "Run %d: Startup=%sms, UIEnter=%sms, Memory=%sKB\n" \
           "$i" "${startup_times[$i]}" "${ui_enter_times[$i]}" "${memory_usages[$i]}"
done

# Export CSV
echo ""
timestamp=$(date +%Y%m%d_%H%M%S)
csv_file="$csv_dir/nvim_benchmark_${timestamp}.csv"

echo "${CYAN}Exporting to CSV: $csv_file${NC}"

# Use dot as decimal separator (international format)
echo '"Run","Startup","UIEnter","Memory"' > "$csv_file"
for i in {1..${#startup_times[@]}}; do
    # Ensure dot as decimal separator
    printf '"%d","%s","%s","%s"\n' \
        "$i" \
        "${startup_times[$i]}" \
        "${ui_enter_times[$i]}" \
        "${memory_usages[$i]}" >> "$csv_file"
done

echo "${GREEN}CSV exported successfully${NC}"

# Export JSON metadata
meta_file="$csv_dir/nvim_benchmark_${timestamp}_meta.json"

echo "${CYAN}Exporting metadata: $meta_file${NC}"

cat > "$meta_file" <<EOF
{
  "timestamp": "$timestamp",
  "runs": $RUNS,
  "startup": {
    "mean": $startup_mean,
    "median": $startup_median,
    "min": $startup_min,
    "max": $startup_max,
    "stddev": $startup_stddev
  },
  "uienter": {
    "mean": $ui_mean,
    "median": $ui_median,
    "min": $ui_min,
    "max": $ui_max,
    "stddev": $ui_stddev
  },
  "memory": {
    "mean": $mem_mean,
    "median": $mem_median,
    "min": $mem_min,
    "max": $mem_max,
    "stddev": $mem_stddev
  }
}
EOF

echo "${GREEN}Metadata exported successfully${NC}"

echo ""
echo "${CYAN}Results saved to:${NC}"
echo "${GRAY}  CSV:  $csv_file${NC}"
echo "${GRAY}  Meta: $meta_file${NC}"

# Cleanup temp files
rm -f /tmp/nvim_startuptime_*_$$.txt 2>/dev/null

echo ""
echo "${GREEN}Benchmark complete! Use :BenchmarkHtml to generate report.${NC}"
