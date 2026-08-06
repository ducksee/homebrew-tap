class DucktermWeb < Formula
  desc "Standalone browser terminal — SolidJS SPA + Node bridge (pure Node.js)"
  homepage "https://github.com/ducksee/DuckTerm"
  url "https://github.com/ducksee/duckterm-web-releases/releases/download/v0.2.9/duckterm-web-v0.2.9-tiny.tar.gz"
  sha256 "b14b23993ca6d19858460aa112dad1b3973e84d9bba4ce587f62f70857f067f3"
  license :cannot_represent # proprietary (see package LICENSE)

  # Runtime commands executed by the packaged Node bridge. Keep tmux/OpenSSL
  # explicit because brew services starts with a stripped PATH. Node is a
  # versioned runtime requirement instead: the tiny package intentionally
  # reuses a compatible nvm/fnm/Volta/asdf/mise/system/Brew installation.
  depends_on "openssl@3"
  depends_on "tmux"

  def install
    libexec.install Dir["*"]
    openssl_bin = formula_opt_bin("openssl@3")
    tmux_bin = formula_opt_bin("tmux")
    (bin/"duckterm-web").write <<~SH
      #!/bin/sh
      export PATH="#{openssl_bin}:#{tmux_bin}:$PATH"
      find_node() {
        for c in "${DUCKTERM_NODE:-}" "$(command -v node 2>/dev/null)" \
          "#{HOMEBREW_PREFIX}/opt/node@24/bin/node" \
          "#{HOMEBREW_PREFIX}/bin/node" \
          "/usr/local/opt/node@24/bin/node" \
          "/usr/local/bin/node" \
          "$HOME"/.nvm/versions/node/*/bin/node \
          "$HOME"/.local/share/fnm/node-versions/*/installation/bin/node \
          "$HOME"/.volta/bin/node \
          "$HOME"/.asdf/installs/nodejs/*/bin/node "$HOME"/.asdf/shims/node \
          "$HOME"/.local/share/mise/installs/node/*/bin/node \
          "$HOME"/.local/share/mise/shims/node; do
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
        echo "duckterm-web: no compatible Node found (HOME=${HOME:-<unset>}, PATH=${PATH:-<unset>})" >&2
        echo "duckterm-web needs Node >= 22.5. Existing nvm/fnm/Volta/asdf/mise/Brew installs are supported; otherwise run: brew install node@24" >&2
        exit 1
      }
      exec "$NODE" "#{libexec}/duckterm.mjs" "$@"
    SH
    chmod 0755, bin/"duckterm-web"
  end

  service do
    run [opt_bin/"duckterm-web"]
    environment_variables HOME: Dir.home, PATH: std_service_path_env
    keep_alive true
    log_path var/"log/duckterm-web.log"
    error_log_path var/"log/duckterm-web.log"
  end

  def caveats
    <<~EOS
      Installs tmux and OpenSSL. DuckTerm Web reuses an existing Node >= 22.5
      from nvm, fnm, Volta, asdf, mise, Homebrew, or PATH instead of installing
      a duplicate Node runtime. If none is present: brew install node@24

      Local tmux sessions work out of the box. SSH/Mosh targets still need tmux
      installed on each remote host where you want persistent sessions.

      Start DuckTerm Web and open the login URL:
        duckterm-web start

      SSH / headless (start and print the URL only):
        duckterm-web start --no-open

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

      Upgrade (one command — refreshes the tap Homebrew won't auto-pull,
      upgrades, and restarts the service):
        duckterm-web upgrade

      Uninstall:
        brew services stop duckterm-web && brew uninstall duckterm-web
    EOS
  end

  test do
    assert_match "duckterm-web #{version}", shell_output("#{bin}/duckterm-web version")
    assert_match(/^tmux /, shell_output("#{formula_opt_bin("tmux")}/tmux -V"))
    assert_match(/^OpenSSL /, shell_output("#{formula_opt_bin("openssl@3")}/openssl version"))
  end
end
