# ducksee/homebrew-tap

```sh
brew install ducksee/tap/duckterm-web
brew services start duckterm-web
```

The formula installs DuckTerm Web's required Node, tmux, and OpenSSL
runtimes. Local persistent tmux sessions therefore work on a clean Mac.
Remote SSH/Mosh hosts still need their own tmux installation.

Print the login URL and first-login bootstrap token with:

```sh
duckterm-web url
```

Persistent LAN/HTTPS:

```sh
duckterm-web config --lan --reload
duckterm-web status
```
