class DucktermWeb < Formula
  desc "Standalone browser terminal — SolidJS SPA + Node bridge (pure Node.js)"
  homepage "https://github.com/ducksee/DuckTerm"
  url "https://github.com/ducksee/duckterm-web-releases/releases/download/v0.2.3/duckterm-web-v0.2.3-tiny.tar.gz"
  version "0.2.3"
  sha256 "caf707921eccd4f878f386d134d7a702333ec0a372e23c21afad3f74e7f70e23"
  license :cannot_represent # proprietary (see package LICENSE)

  # No `depends_on "node"`: the "tiny" tarball is designed to REUSE whatever
  # Node >= 22.5 you already have (system / brew / nvm) — Homebrew shouldn't
  # install a second copy. The wrapper resolves node at runtime (nvm paths
  # included, since launchd/brew-services start with a stripped PATH).

  def install
    libexec.install Dir["*"]
    (bin/"duckterm-web").write <<~SH
      #!/bin/sh
      find_node() {
        for c in "$(command -v node 2>/dev/null)" \
          /opt/homebrew/bin/node /usr/local/bin/node /usr/bin/node \
          "$HOME"/.nvm/versions/node/*/bin/node; do
          [ -x "$c" ] || continue
          v=$("$c" -p 'process.versions.node' 2>/dev/null) || continue
          maj=${v%%.*}; rest=${v#*.}; min=${rest%%.*}
          if [ "$maj" -gt 22 ] 2>/dev/null || { [ "$maj" -eq 22 ] && [ "$min" -ge 5 ]; } 2>/dev/null; then
            echo "$c"; return 0
          fi
        done
        return 1
      }
      NODE=$(find_node) || {
        echo "duckterm-web needs Node >= 22.5. Install it (brew install node) and retry." >&2
        exit 1
      }
      exec "$NODE" "#{libexec}/duckterm.mjs" "$@"
    SH
    chmod 0o755, bin/"duckterm-web"
  end

  service do
    run [opt_bin/"duckterm-web"]
    keep_alive true
    log_path var/"log/duckterm-web.log"
    error_log_path var/"log/duckterm-web.log"
  end

  def caveats
    <<~EOS
      Reuses your existing Node (>= 22.5) — no extra node installed.
      Start as a persistent service:
        brew services start duckterm-web

      Get the login URL (incl. the first-login bootstrap token):
        duckterm-web url

      Runtime config lives at:
        ~/.duckterm/config.json

      Enable persistent LAN + HTTPS:
        duckterm-web config --lan --reload

      Back to localhost + HTTP:
        duckterm-web config --local --reload

      Change port:
        duckterm-web config --port 1443 --reload

      Inspect current state (version + update check):
        duckterm-web status
        duckterm-web version

      Foreground one-off LAN + HTTPS:
        duckterm-web --lan

      Upgrading (Homebrew won't restart a running service for you):
        brew upgrade duckterm-web && brew services restart duckterm-web

      Uninstall:
        brew services stop duckterm-web && brew uninstall duckterm-web
    EOS
  end
end
