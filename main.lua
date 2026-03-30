local M = {}

function M:entry(job)
  local mode = job.args and job.args[1] or "fd"
  local tl_depth = job.args.TL and tostring(job.args.TL) or "3"
  local bat_style = "plain"

  local function get_tree_cmd(target)
    return 'printf "   Tree Structure\\n  \\033[2m────────────────\\033[0m\\n"; eza -TL=' ..
        tl_depth ..
        ' --color=always --icons=always --group-directories-first --no-quotes ' .. target .. ' 2>/dev/null | tail -n +2'
  end

  local script
  if mode == "fd" then
    script = [[
      root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
      cd "$root" || exit 1
      result=$(
        fzf \
          --height=100% --layout=reverse --info=inline-right --scheme=path \
          --prompt " Find Files: ➜ " --pointer="▶" --separator "─" --scrollbar "│" --border="rounded" --padding="1,2" \
          --header " ENTER: Edit |  CTRL-E: Show File" \
          --bind "start:reload:echo ''" \
          --bind "change:reload:[ -z {q} ] && echo '' || fd --type f --type l --exclude '.*' --max-depth 6" \
          --bind "ctrl-j:down,ctrl-k:up" \
          --bind "enter:become(echo EDIT:{})" \
          --bind "ctrl-e:become(echo REVEAL:{})" \
          --preview 'if [ -z {} ]; then ]] ..
        get_tree_cmd(".") ..
        [[; else bat --style=]] .. bat_style .. [[ --color=always {} 2>/dev/null || ]] .. get_tree_cmd("{}") .. [[; fi' \
          --preview-window="right:50%:wrap:border-left"
      )
      [ -z "$result" ] && exit 0
      case "$result" in
        EDIT:*) file="${result#EDIT:}"; ya emit reveal "$root/$file"; ${EDITOR:-nvim} "$root/$file" ;;
        REVEAL:*) file="${result#REVEAL:}"; ya emit reveal "$root/$file" ;;
      esac
    ]]
  elseif mode == "rg" then
    script = [[
      root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
      cd "$root" || exit 1
      result=$(
        fzf \
          --ansi --disabled --height=100% --layout=reverse --info=inline-right \
          --prompt " Ripgrep: ➜ " --pointer="▶" --separator "─" --scrollbar "│" --border="rounded" --padding="1,2" \
          --header " ENTER: Edit |  CTRL-E: Show File" --delimiter : \
          --bind "start:reload:echo ''" \
          --bind "change:reload:[ -z {q} ] && echo '' || (rg --column --line-number --no-heading --color=always --smart-case --sort path --glob '!.*' -- $(echo {q} | sed 's/ /.*/g') .) || true" \
          --bind "ctrl-j:down,ctrl-k:up" \
          --bind "enter:become(echo EDIT:{})" \
          --bind "ctrl-e:become(echo REVEAL:{})" \
          --preview 'if [ -z {} ]; then ]] ..
        get_tree_cmd(".") ..
        [[; else bat --style=]] ..
        bat_style .. [[ --color=always --highlight-line {2} {1} 2>/dev/null || ]] .. get_tree_cmd("{1}") .. [[; fi' \
          --preview-window="right:50%:wrap:border-left:+{2}+3/3:~3"
      )
      [ -z "$result" ] && exit 0
      case "$result" in
        EDIT:*) selection="${result#EDIT:}"; file=$(echo "$selection" | cut -d: -f1); line=$(echo "$selection" | cut -d: -f2); ya emit reveal "$root/$file"; ${EDITOR:-nvim} "+$line" "$root/$file" ;;
        REVEAL:*) selection="${result#REVEAL:}"; file=$(echo "$selection" | cut -d: -f1); ya emit reveal "$root/$file" ;;
      esac
    ]]
  elseif mode == "zoxide" then
    script = [[
      result=$(
        zoxide query -ls 2>/dev/null \
        | awk -v home="$HOME" '{
            w=8-length($1); pad=""; for(i=0;i<w;i++) pad=pad" ";
            display=$NF; sub("^" home, "~", display);
            # \033[32m is Green, \033[0m resets it
            print pad "\033[32m" $1 "\033[0m │ " display "\t" $NF
          }' \
        | fzf \
            --ansi --no-sort --height=100% --layout=reverse --info=inline-right --scheme=path --delimiter='\t' --with-nth=1 \
            --prompt "󰰷 Zoxide: ➜ " --pointer="▶" --separator "─" --scrollbar "│" --border="rounded" --padding="1,2" \
            --header "   Rank │  Directory" \
            --bind "ctrl-j:down,ctrl-k:up" \
            --preview ']] .. get_tree_cmd("{2}") .. [[' \
            --preview-window="right:50%:wrap:border-left" \
        | cut -f2
      )
      [ -z "$result" ] && exit 0
      ya emit cd "$result"
    ]]
  end
  ya.emit("shell", { script, block = true })
end

return M
