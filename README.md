# ducksee/homebrew-tap

## DuckTerm Hookd

Install the Hookd runtime and bundled local Web UI, then run guided setup to
pair the machine, connect detected coding agents, and start the background
service:

```sh
brew install ducksee/tap/duckterm-hookd
duckterm-hookd setup --qr
duckterm-hookd status
```

`setup --qr` is safe to rerun: an existing pairing is kept while agent
integrations and service readiness are reconciled. `duckterm-hookd hook
install` changes only DuckTerm-owned coding-agent Hooks; it is not a package
installer. Update the complete runtime with `duckterm-hookd update`.

Full install, upgrade, unpair, and removal semantics are documented in
[duckterm-hookd-releases](https://github.com/ducksee/duckterm-hookd-releases#readme).

## DuckTerm Web

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
