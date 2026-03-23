<div align="center">

# fzf-search.yazi
<br>

## Demo
<br>

**Find Files**

<img src="https://raw.githubusercontent.com/onelocked/fuzzy-search.yazi/refs/heads/main/.github/fd-search.gif" width="640">

<br>
<br>

**Ripgrep Search**
<br>
<img src="https://raw.githubusercontent.com/onelocked/fuzzy-search.yazi/refs/heads/main/.github/rg-search.gif" width="640">
<br>

**Zoxide**
<br>
<img src="./zoxide.png" width="640">
<br>
</div>

# Requirements
```bash
eza # for directory tree
bat # for pretty preview
fzf # for fuzzy finding
zoxide # optional
```

# Installation

**Add fuzzy-search.yazi as a flake input**
```nix
# In your flake.nix
inputs.fuzzy-search-yazi.url = "github:onelocked/fuzzy-search.yazi;
```

**Home-Manager Yazi config**
```nix
# In your yazi config
programs.yazi.plugins = {
fuzzy-search = inputs.fuzzy-search.yazi.packages.${pkgs.stdenv.hostPlatform.system}.default;
};
```

```nix
# Then add keymaps for yazi
programs.yazi.keymap = {
        mgr.prepend_keymap = [
          {
            on = [ "z" ];
            run = "plugin fuzzy-search -- fd --TL=3";
            desc = "Fuzzy Find Files";
          }
          {
            on = [ "<S-s>" ];
            run = "plugin fuzzy-search -- rg --TL=3";
            desc = "Ripgrep Search";
          }
          {
            on = [ "<S-z>" ];
            run = "plugin fuzzy-search -- zoxide --TL=3";
            desc = "Zoxide Search";
          }
  ];
};
```
