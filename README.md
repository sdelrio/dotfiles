# dotfiles

Code used for setup inital terminal and cli tools

## `install.sh` 

* Install nix in determinate mode
* Install devbox
* If pop-os setup zsh as the shell
* Install devbox global packages

## `sync.sh`

* Sync dotfiles with parent folder (`$HOME`) making symlinks using `stow`.
* Render the global devbox config per platform: Linux / Apple Silicon symlink
  `.local/share/devbox/global/default/devbox.json`; Intel macOS gets a generated
  file pinning nixpkgs `26.05` (last release with `x86_64-darwin`). `devbox.json`
  is JSONC — each package carries a `//` one-liner saying what the tool does;
  `sync.sh` strips those comments before rendering the Intel file (jq is strict JSON).

After syncing, apply packages with **`devbox global install`**. Prefer it over
`devbox global update`: on Intel the generated packages are version-less and
locked to the 26.05 commit, so `update` only logs `nix profile upgrade` warnings
before reinstalling the same set.

