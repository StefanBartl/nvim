#!/usr/bin/env zsh
#
# Automated Neovim startup benchmarking with warmup run
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
LUA_SCRIPT="$HOME/.config/nvim/lua/debugging/performance/scripts/benchmark_startup.lua"
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

# Function to run nvim with timeout
run_nvim_with_timeout() {
    local startupfile=$1
    local timeout=$2

    export NVIM_STARTUPTIME_FILE="$startupfile"

    # Run nvim in background and capture PID
    "$NVIM_EXE" --headless --startuptime "$startupfile" \
                -c "luafile $LUA_SCRIPT" 2>&1 &
    local nvim_pid=$!

    # Wait for process with timeout
    local count=0
    local max_count=$((timeout * 10))  # Check every 0.1s

    while kill -0 $nvim_pid 2>/dev/null; do
        sleep 0.1
        ((count++))
        if ((count >= max_count)); then
            # Timeout reached, kill the process
            kill -9 $nvim_pid 2>/dev/null
            wait $nvim_pid 2>/dev/null
            return 124  # Timeout exit code
        fi
    done

    # Process finished, get its output
    wait $nvim_pid
    return $?
}

# Storage arrays
startup_times=()
ui_enter_times=()

# Warmup run (unless skipped)
if ((SKIP_WARMUP == 0)); then
    echo "${CYAN}Running warmup...${NC}"

    warmup_file="/tmp/nvim_startuptime_warmup_$$.txt"
    run_nvim_with_timeout "$warmup_file" 10 > /dev/null 2>&1

    sleep 0.5
    echo "${GREEN}Warmup complete${NC}\n"
fi

echo "${CYAN}Starting $RUNS benchmark runs...${NC}\n"

# Run benchmarks
for i in {1..$RUNS}; do
    printf "Run %d/%d... " "$i" "$RUNS"

    # Create temp file for startuptime
    startupfile="/tmp/nvim_startuptime_${i}_$$.txt"
    export NVIM_STARTUPTIME_FILE="$startupfile"

    # Run Neovim with timeout
    output=$("$NVIM_EXE" --headless --startuptime "$startupfile" \
                         -c "luafile $LUA_SCRIPT" 2>&1 &)
    nvim_pid=$!

    # Wait with timeout
    local count=0
    while kill -0 $nvim_pid 2>/dev/null && ((count < 50)); do
        sleep 0.1
        ((count++))
    done

    # Check if still running (timeout)
    if kill -0 $nvim_pid 2>/dev/null; then
        kill -9 $nvim_pid 2>/dev/null
        wait $nvim_pid 2>/dev/null
        echo "${RED}TIMEOUT - killed${NC}"
        continue
    fi

    # Get output
    wait $nvim_pid
    output=$("$NVIM_EXE" --headless --startuptime "$startupfile" \
                         -c "luafile $LUA_SCRIPT" 2>&1)

    if ((DEBUG == 1)); then
        echo "\n${MAGENTA}DEBUG OUTPUT:${NC}"
        echo "$output" | while IFS= read -r line; do
            echo "${GRAY}  $line${NC}"
        done
        echo ""
    fi

    # Look for the timing line
    timing_line=$(echo "$output" | grep -E '^\d+\.\d+,\d+\.\d+$' | head -n1)

    if [[ "$timing_line" =~ ^([0-9.]+),([0-9.]+)$ ]]; then
        startup="${match[1]}"
        ui_enter="${match[2]}"

        startup_times+=($startup)
        ui_enter_times+=($ui_enter)

        echo "${GREEN}Startup: ${startup}ms, UI Enter: ${ui_enter}ms${NC}"
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

echo "${CYAN}=== Results ===${NC}\n"

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

# Startup stats
read -r startup_mean startup_median startup_min startup_max startup_stddev <<< \
    $(calculate_stats "${startup_times[@]}")

# UI Enter stats
read -r ui_mean ui_median ui_min ui_max ui_stddev <<< \
    $(calculate_stats "${ui_enter_times[@]}")

echo "${YELLOW}Startup Time (ms):${NC}"
echo "  Mean:   $startup_mean"
echo "  Median: $startup_median"
echo "  Min:    $startup_min"
echo "  Max:    $startup_max"
echo "  StdDev: $startup_stddev"

echo "\n${YELLOW}UI Enter Time (ms):${NC}"
echo "  Mean:   $ui_mean"
echo "  Median: $ui_median"
echo "  Min:    $ui_min"
echo "  Max:    $ui_max"
echo "  StdDev: $ui_stddev"

echo "\n${CYAN}=== Raw Data ===${NC}"
for i in {1..${#startup_times[@]}}; do
    printf "Run %d: Startup=%sms, UIEnter=%sms\n" \
           "$i" "${startup_times[$i]}" "${ui_enter_times[$i]}"
done

# Export CSV
csv_file="./Resultate/csv/nvim_benchmark_$(date +%Y%m%d_%H%M%S).csv"
echo "Run,Startup,UIEnter" > "$csv_file"
for i in {1..${#startup_times[@]}}; do
    echo "$i,${startup_times[$i]},${ui_enter_times[$i]}" >> "$csv_file"
done

echo "\n${CYAN}CSV exported: $csv_file${NC}"

# Cleanup temp files
rm -f /tmp/nvim_startuptime_*_$$.txt 2>/dev/null
