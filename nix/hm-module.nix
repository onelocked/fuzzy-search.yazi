{
  config,
  lib,
  pkgs,
  fuzzy-search-pkgs,
  ...
}:
let
  cfg = config.programs.yazi.yaziPlugins.plugins.fuzzy-search;
in
{
  options.programs.yazi.yaziPlugins.plugins.fuzzy-search = {
    enable = lib.mkEnableOption "fuzzy-search yazi plugin";

    package = lib.mkOption {
      type = lib.types.package;
      default = fuzzy-search-pkgs;
      description = "The fuzzy-search yazi plugin package.";
    };

    depth = lib.mkOption {
      type = lib.types.int;
      default = 3;
      description = "The maximum depth for the search (sets the --TL flag).";
    };

    enableFishIntegration = lib.mkEnableOption "Fish shell integration for fuzzy-zoxide search";

    keymaps = {
      fd = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to add the default keymap (z) for fd fuzzy search.";
      };
      rg = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to add the default keymap (<S-s>) for Ripgrep search.";
      };
      zoxide = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to add the default keymap (<S-z>) for Zoxide search.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure all binaries used in the Fish script and Yazi plugin are available
    home.packages = [
      pkgs.fzf
      pkgs.eza
      pkgs.bat
      pkgs.gawk
    ]
    ++ lib.optional (cfg.keymaps.fd) pkgs.fd
    ++ lib.optional (cfg.keymaps.rg) pkgs.ripgrep
    ++ lib.optional (cfg.keymaps.zoxide || cfg.enableFishIntegration) pkgs.zoxide;

    programs.yazi.plugins = {
      fuzzy-search = cfg.package;
    };

    programs.fish = lib.mkIf cfg.enableFishIntegration {
      functions."__yazi-fuzzy-zoxide" = {
        description = "Fuzzy search zoxide results and open in Yazi";
        body = # fish
          ''
            set -l dir (
              zoxide query -ls 2>/dev/null \
              | awk -v home="$HOME" '{
                  score = $1
                  sub(/^[ \t]*[0-9.]+[ \t]+/, "", $0)
                  orig = $0
                  sub("^" home, "~", $0)

                  green = "\033[32m"
                  dim   = "\033[2m"
                  reset = "\033[0m"

                  printf "%s%6s %s│%s  %s\t%s\n", green, score, reset dim, reset, $0, orig
              }' \
              | fzf \
                  --ansi --no-sort --height=100% --layout=reverse --info=inline-right \
                  --scheme=path --delimiter='\t' --with-nth=1 \
                  --prompt "󰰷 Zoxide: ➜ " --pointer="▶" --separator "─" \
                  --scrollbar "│" --border="rounded" --padding="1,2" \
                  --header " Rank │  Directory" \
                  --preview 'eza -TL=${toString cfg.depth} --color=always --icons {2} 2>/dev/null || ls {2}' \
                  --preview-window="right:50%:wrap" \
                  --bind "ctrl-j:down,ctrl-k:up" \
                  --bind "ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up" \
              | cut -f2 | string trim
            )

            if test -n "$dir"
                cd "$dir"
                ${config.programs.yazi.shellWrapperName}
                zoxide add "$dir"
            end
            commandline -f repaint
          '';
      };

      interactiveShellInit = ''
        bind Z __yazi-fuzzy-zoxide
        bind -M insert Z __yazi-fuzzy-zoxide
      '';
    };

    programs.yazi.keymap = lib.mkIf (cfg.keymaps.fd || cfg.keymaps.rg || cfg.keymaps.zoxide) {
      mgr.prepend_keymap =
        (lib.optional cfg.keymaps.fd {
          on = [ "z" ];
          run = "plugin fuzzy-search -- fd --TL=${toString cfg.depth}";
          desc = "Fuzzy Find Files";
        })
        ++ (lib.optional cfg.keymaps.rg {
          on = [ "<S-s>" ];
          run = "plugin fuzzy-search -- rg --TL=${toString cfg.depth}";
          desc = "Ripgrep Search";
        })
        ++ (lib.optional cfg.keymaps.zoxide {
          on = [ "<S-z>" ];
          run = "plugin fuzzy-search -- zoxide --TL=${toString cfg.depth}";
          desc = "Zoxide Search";
        });
    };
  };
}
