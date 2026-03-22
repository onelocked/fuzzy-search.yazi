local M = {}

function M:entry(job)
  local mode = job.args and job.args[1] or "fd"
  local script

  if mode == "fd" then
    script = [[
      root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
      cd "$root" || exit 1
      selected=$(
        fzf \
          --disabled \
          --height=100% \
          --scheme=path \
          --bind "start:reload:echo ''" \
          --bind "change:reload:([ -z {q} ] && echo '' || fd --type f --type l --exclude .git --max-depth 6 {q}) || true" \
          --prompt "fd> " \
          --preview "if [ -z {} ]; then
            eza -TL=3 --color=always --icons=always --group-directories-first --no-quotes .
          else
            bat --style=numbers,changes --color=always {} 2>/dev/null || eza -TL=3 --color=always --icons=always --group-directories-first --no-quotes {}
          fi" \
          --preview-window=right:55%:border-left
      )
      [ -n "$selected" ] && ya emit reveal "$root/$selected"
      exit 0
    ]]
  elseif mode == "rg" then
    script = [[
      root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
      cd "$root" || exit 1
      selected=$(
        fzf \
          --ansi --disabled \
          --height=100% \
          --prompt "rg> " \
          --delimiter : \
          --bind "start:reload:echo ''" \
          --bind "change:reload:([ -z {q} ] && echo '' || rg --column --line-number --no-heading --color=always --smart-case --glob '!.git' -- {q} .) || true" \
          --preview "if [ -z {} ]; then
            eza -TL=3 --color=always --icons=always --group-directories-first --no-quotes .
          else
            bat --style=numbers --color=always --highlight-line {2} {1} 2>/dev/null
          fi" \
          --preview-window "right:55%:border-left:+{2}+3/3:~3"
      )
      [ -n "$selected" ] && ya emit reveal "$root/$(echo "$selected" | cut -d: -f1)"
      exit 0
    ]]
  end
  ya.emit("shell", { script, block = true })
end

return M
