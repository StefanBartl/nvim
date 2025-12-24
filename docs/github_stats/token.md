# githuib_stats token setup

## Environment Variable

export GITHUB_TOKEN="ghp_..."

"token_source": "env",
"token_env_var": "NEOVIM_STATS_TOKEN",

## Oder File-basiert

echo "ghp_..." > ~/.github_token
chmod 600 ~/.github_token

"token_source": "file",
"token_file": "~/.github_token"

