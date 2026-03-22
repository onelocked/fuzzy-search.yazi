local M = {}

function M:entry(job)
  local mode = job.args and job.args[1] or "fd"
  local script = ""

  if mode == "fd" then
    script = [[
            root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
            selected=$(fd . "$root" -t f --hidden --exclude .git --max-depth 5 | sed "s|$root/||" | fzf --height=100% --preview "bat --color=always $root/{} 2>/dev/null || ls --color=always $root/{}" --preview-window=right:50%)
            [ -n "$selected" ] && ya emit reveal "$root/$selected"
        ]]
  elseif mode == "rg" then
    script = [[
            root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
            cd "$root" || exit 1

            # The core Ripgrep command
            RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case"

            # fzf is set to --disabled, meaning it doesn't filter on its own.
            # Instead, change:reload runs rg dynamically every time you type!
            selected=$(
                FZF_DEFAULT_COMMAND="$RG_PREFIX ''" \
                fzf --bind "change:reload:$RG_PREFIX {q} || true" \
                    --ansi --disabled \
                    --height=100% \
                    --delimiter : \
                    --preview 'bat --style=full --color=always --highlight-line {2} {1} 2>/dev/null' \
                    --preview-window 'right,50%,border-left,+{2}+3/3,~3'
            )

            # Extract just the filename and reveal it in Yazi
            [ -n "$selected" ] && ya emit reveal "$root/$(echo "$selected" | cut -d: -f1)"
        ]]
  end

  ya.emit("shell", {
    script,
    block = true,
  })
end

return M
