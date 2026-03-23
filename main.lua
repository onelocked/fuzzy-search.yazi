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
      result=$(
        fzf \
          --height=100% \
          --layout=reverse \
          --info=inline-right \
          --scheme=path \
          --prompt "  Find Files: ➜ " \
          --separator "─" \
          --scrollbar "│" \
          --border="rounded" \
          --padding="1,2" \
          --header " ENTER: Show File |  CTRL-E: Edit" \
          --bind "start:reload:echo ''" \
          --bind "change:reload:[ -z {q} ] && echo '' || fd --type f --type l --exclude '.*' --max-depth 6" \
          --bind "ctrl-j:down,ctrl-k:up" \
          --bind "ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up" \
          --bind "ctrl-e:become(echo EDIT:{})" \
          --preview "if [ -z {} ]; then
            eza -TL=]] .. tl_depth .. [[ --color=always --icons=always --group-directories-first --no-quotes .
          else
            bat --style=]] ..
        bat_style ..
        [[ --color=always {} 2>/dev/null || eza -TL=]] ..
        tl_depth .. [[ --color=always --icons=always --group-directories-first --no-quotes {}
          fi" \
          --preview-window="right:57%:border-left"
      )

      [ -z "$result" ] && exit 0

      case "$result" in
        EDIT:*)
          file="${result#EDIT:}"
          ya emit reveal "$root/$file"
          ${EDITOR:-nvim} "$root/$file"
          ;;
        *)
          ya emit reveal "$root/$result"
          ;;
      esac
    ]]
  elseif mode == "rg" then
    script = [[
      root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
      cd "$root" || exit 1
      result=$(
        fzf \
          --ansi --disabled \
          --height=100% \
          --layout=reverse \
          --info=inline-right \
          --prompt "  Ripgrep: ➜ " \
          --separator "─" \
          --scrollbar "│" \
          --border="rounded" \
          --padding="1,2" \
          --header " ENTER: Show File |  CTRL-E: Edit" \
          --delimiter : \
          --bind "start:reload:echo ''" \
          --bind "change:reload:[ -z {q} ] && echo '' || (rg --column --line-number --no-heading --color=always --smart-case --sort path --glob '!.*' -- $(echo {q} | sed 's/ /.*/g') .) || true" \
          --bind "ctrl-j:down,ctrl-k:up" \
          --bind "ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up" \
          --bind "ctrl-e:become(echo EDIT:{})" \
          --preview "if [ -z {} ]; then
            eza -TL=]] .. tl_depth .. [[ --color=always --icons=always --group-directories-first --no-quotes .
          else
            bat --style=]] .. bat_style .. [[ --color=always --highlight-line {2} {1} 2>/dev/null
          fi" \
          --preview-window="right:57%:border-left:+{2}+3/3:~3"
      )

      [ -z "$result" ] && exit 0

      case "$result" in
        EDIT:*)
          selection="${result#EDIT:}"
          file=$(echo "$selection" | cut -d: -f1)
          line=$(echo "$selection" | cut -d: -f2)
          ya emit reveal "$root/$file"
          ${EDITOR:-nvim} "+$line" "$root/$file"
          ;;
        *)
          file=$(echo "$result" | cut -d: -f1)
          ya emit reveal "$root/$file"
          ;;
      esac
    ]]
  end
  ya.emit("shell", { script, block = true })
end

return M
