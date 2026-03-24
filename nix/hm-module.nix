{
  config,
  lib,
  pkgs,
  fuzzy-search-pkgs,
  ...
}:
let
  cfg = config.programs.yazi.fuzzy-search;
in
{
  options.programs.yazi.fuzzy-search = {
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
    home.packages = [
      pkgs.fzf
      pkgs.eza
      pkgs.bat
    ]
    ++ lib.optional cfg.keymaps.fd pkgs.fd
    ++ lib.optional cfg.keymaps.rg pkgs.ripgrep
    ++ lib.optional cfg.keymaps.zoxide pkgs.zoxide;

    programs.yazi.plugins = {
      fuzzy-search = cfg.package;
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
