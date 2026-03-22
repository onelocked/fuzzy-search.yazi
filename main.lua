local M = {}

function M:entry(job)
  local mode = job.args and job.args[1] or "fd"
  local script

  if mode == "fd" then
    script = [[
      root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
      selected=$(
        fd . "$root" -t f --hidden --exclude .git --max-depth 5 \
          | sed "s|$root/||" \
          | fzf \
              --height=100% \
              --scheme=path \
              --preview "bat --style=numbers,changes --color=always '$root/{}' 2>/dev/null || ls --color=always '$root/{}'" \
              --preview-window=right:55%:border-left
      )
      [ -n "$selected" ] && ya emit reveal "$root/$selected"
    ]]

  elseif mode == "rg" then
    script = [[
      root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
      cd "$root" || exit 1
      RG="rg --column --line-number --no-heading --color=always --smart-case --hidden --glob=!.git"
      selected=$(
        fzf \
          --disabled --ansi \
          --height=100% \
          --bind "start:reload:$RG {q} || true" \
          --bind "change:reload:$RG {q} || true" \
          --bind "ctrl-f:unbind(change,ctrl-f)+enable-search+transform-prompt(echo 'fzf> ')+transform-search-query()" \
          --bind "ctrl-r:unbind(ctrl-r)+disable-search+transform-prompt(echo 'rg> ')+reload:$RG {q} || true+rebind(change,ctrl-f)" \
          --prompt "rg> " \
          --delimiter : \
          --preview "bat --style=numbers --color=always --highlight-line {2} {1} 2>/dev/null" \
          --preview-window "right:55%:border-left:+{2}+3/3:~3"
      )
      [ -n "$selected" ] && ya emit reveal "$root/$(echo "$selected" | cut -d: -f1)"
    ]]
  end

  ya.emit("shell", { script, block = true, confirm = true })
end

return M
