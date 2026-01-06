# Preparations fpor benchmarks

```sh
# Clear all caches
rm -rf ~/.cache/nvim
rm -rf ~/.local/share/nvim

# Ensure clean state
killall nvim 2>/dev/null

# Verify no background processes
pgrep nvim
```

## During benchmnarks

```sh
# In another terminal
watch -n 1 'ps aux | grep nvim | wc -l'
```

Should oscillate between 0 and 1.

## After benchmarks

```sh
# Check for hung processes
pgrep nvim

# Clean up temp files
rm -f /tmp/nvim_startuptime_*
```
