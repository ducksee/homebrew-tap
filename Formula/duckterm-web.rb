class DucktermWeb < Formula
  desc "Standalone browser terminal — SolidJS SPA + Node bridge (pure Node.js)"
  homepage "https://github.com/ducksee/DuckTerm"
  url "https://github.com/ducksee/duckterm-web-releases/releases/download/v0.2.6/duckterm-web-v0.2.6-tiny.tar.gz"
  sha256 "4f657941b3c689ab0226dea54f099f428c54a3862b00c582a893a5b0cb03975f"
  license :cannot_represent # proprietary (see package LICENSE)
  revision 1

  # Runtime commands executed by the packaged Node bridge. Keep these explicit:
  # brew services starts with a stripped PATH, and a clean Mac has neither Node
  # nor tmux. OpenSSL generates the HTTPS certificate used by LAN mode.
  depends_on "node@24"
  depends_on "openssl@3"
  depends_on "tmux"

  def install
    libexec.install Dir["*"]
    node_bin = formula_opt_bin("node@24")
    openssl_bin = formula_opt_bin("openssl@3")
    tmux_bin = formula_opt_bin("tmux")
    (bin/"duckterm-web").write <<~SH
      #!/bin/sh
      export PATH="#{node_bin}:#{openssl_bin}:#{tmux_bin}:$PATH"
      exec "#{node_bin}/node" "#{libexec}/duckterm.mjs" "$@"
    SH
    chmod 0755, bin/"duckterm-web"
  end

  service do
    run [opt_bin/"duckterm-web"]
    keep_alive true
    log_path var/"log/duckterm-web.log"
    error_log_path var/"log/duckterm-web.log"
  end

  def caveats
    <<~EOS
      Installs the Node, tmux, and OpenSSL runtimes used by DuckTerm Web.
      Local tmux sessions work out of the box. SSH/Mosh targets still need
      tmux installed on each remote host where you want persistent sessions.

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
