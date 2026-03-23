local M = {}

function M:entry(job)
  local mode = job.args and job.args[1] or "fd"
  local tl_depth = job.args.TL and tostring(job.args.TL) or "3"
  local bat_style = "plain"

  local script
  if mode == "fd" then
    script = [[
      root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
      cd "$root" || exit 1
      selected=$(
        fzf \
          --height=100% \
          --layout=reverse \
          --info=inline \
          --scheme=path \
          --tiebreak=length,begin \
          --prompt "fd> " \
          --bind "start:reload:echo ''" \
          --bind "change:reload:[ -z {q} ] && echo '' || fd --type f --type l --exclude '.*' --max-depth 6" \
          --preview "if [ -z {} ]; then
            eza -TL=]] .. tl_depth .. [[ --color=always --icons=always --group-directories-first --no-quotes .
          else
            bat --style=]] ..
        bat_style ..
        [[ --color=always {} 2>/dev/null || eza -TL=]] ..
        tl_depth .. [[ --color=always --icons=always --group-directories-first --no-quotes {}
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
          --layout=reverse \
          --info=inline \
          --prompt "rg> " \
          --delimiter : \
          --bind "start:reload:echo ''" \
          --bind "change:reload:[ -z {q} ] && echo '' || (rg --column --line-number --no-heading --color=always --smart-case --sort path --glob '!.*' -- $(echo {q} | sed 's/ /.*/g') .) || true" \
          --preview "if [ -z {} ]; then
            eza -TL=]] .. tl_depth .. [[ --color=always --icons=always --group-directories-first --no-quotes .
          else
            bat --style=]] .. bat_style .. [[ --color=always --highlight-line {2} {1} 2>/dev/null
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
