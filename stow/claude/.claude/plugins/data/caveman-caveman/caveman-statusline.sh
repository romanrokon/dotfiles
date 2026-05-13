#!/usr/bin/env bash
input=$(cat)

cost=$(printf '%s' "$input" | jq -r '.cost.total_cost_usd // 0 | . * 1000 | round / 1000 | "$\(.)"' 2>/dev/null)
ctx_pct=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // "?" | if . == "?" then "?" else (. | round | tostring + "%") end' 2>/dev/null)
total_tok=$(printf '%s' "$input" | jq -r '.context_window.total_input_tokens // 0 | . / 1000 | . * 10 | round / 10 | tostring + "k"' 2>/dev/null)
model=$(printf '%s' "$input" | jq -r '.model.display_name // ""' 2>/dev/null)
vim_mode=$(printf '%s' "$input" | jq -r '.vim.mode // ""' 2>/dev/null)
branch=$(git -C "$(printf '%s' "$input" | jq -r '.cwd // "."' 2>/dev/null)" rev-parse --abbrev-ref HEAD 2>/dev/null)

usage_5h=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty | round | tostring + "%"' 2>/dev/null)
usage_7d=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty | round | tostring + "%"' 2>/dev/null)

parts=()
[[ -n "$vim_mode" ]] && parts+=("$vim_mode")
[[ -n "$model" ]] && parts+=("$model")
[[ -n "$branch" ]] && parts+=("$branch")
parts+=("$cost")
parts+=("ctx:$ctx_pct ($total_tok)")
[[ -n "$usage_5h" ]] && parts+=("5h:$usage_5h")
[[ -n "$usage_7d" ]] && parts+=("7d:$usage_7d")

printf '%s' "$(IFS=' | '; echo "${parts[*]}")"
