local M = {}
function M:entry(job)
  local mode = job.args and job.args[1] or "fd"
  local script
  if mode == "fd" then
    script = [[
      root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
      selected=$(
        fzf \
          --disabled \
          --height=100% \
          --scheme=path \
          --bind "start:reload:echo ''" \
          --bind "change:reload:[ -z {q} ] && echo '' || fd . \"$root\" -t f -t l --exclude .git --max-depth 6 | sed \"s|$root/||\" | fzf --filter={q}" \
          --prompt "fd> " \
          --preview "bat --style=numbers,changes --color=always '$root/{}' 2>/dev/null || ls --color=always '$root/{}'" \
          --preview-window=right:55%:border-left
      )
      [ -n "$selected" ] && ya emit reveal "$root/$selected"
      exit 0
    ]]
  elseif mode == "rg" then
    script = [[
      root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
      cd "$root" || exit 0
      rg_script=$(mktemp)
      chmod +x "$rg_script"
      cat > "$rg_script" << 'EOF'
#!/bin/sh
if [ -z "$1" ]; then
  exit 0
fi
rg \
  --column \
  --line-number \
  --no-heading \
  --color=always \
  --smart-case \
  --glob '!.git' \
  -- "$@" .
EOF
      selected=$(
        fzf \
          --disabled --ansi \
          --height=100% \
          --bind "start:reload:\"$rg_script\" {q} || true" \
          --bind "change:reload:\"$rg_script\" {q} || true" \
          --bind "ctrl-f:unbind(change,ctrl-f)+enable-search+change-prompt(fzf> )" \
          --bind "ctrl-r:unbind(ctrl-r)+disable-search+change-prompt(rg> )+reload:\"$rg_script\" {q} || true+rebind(change,ctrl-f)" \
          --prompt "rg> " \
          --delimiter : \
          --preview "bat --style=numbers --color=always --highlight-line {2} {1} 2>/dev/null" \
          --preview-window "right:55%:border-left:+{2}+3/3:~3"
      )
      rm -f "$rg_script"
      [ -n "$selected" ] && ya emit reveal "$root/$(echo "$selected" | cut -d: -f1)"
      exit 0
    ]]
  end
  ya.emit("shell", { script, block = true })
end

return M
