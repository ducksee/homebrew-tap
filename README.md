# ducksee/homebrew-tap

```sh
brew install ducksee/tap/duckterm-web
brew services start duckterm-web
```

The first-login URL is printed to:

```sh
tail -n 80 "$(brew --prefix)/var/log/duckterm-web.log"
```

Persistent LAN/HTTPS:

```sh
duckterm-web config --lan --reload
duckterm-web status
```
