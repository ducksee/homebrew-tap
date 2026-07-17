# ducksee/homebrew-tap

```sh
brew install ducksee/tap/duckterm-web
brew services start duckterm-web
```

The formula installs tmux and OpenSSL. It reuses an existing Node >= 22.5
from nvm, fnm, Volta, asdf, mise, Homebrew, or `PATH` rather than installing a
duplicate Node runtime. If no compatible Node exists, install one with
`brew install node@24`.

Local persistent tmux sessions work out of the box. Remote SSH/Mosh hosts
still need their own tmux installation.

Print the login URL and first-login bootstrap token with:

```sh
duckterm-web url
```

Persistent LAN/HTTPS:

```sh
duckterm-web config --lan --reload
duckterm-web status
```
