# typed: false
# frozen_string_literal: true
#
# Brew formula for duckterm-hookd. Source of truth lives at
# tools/duckterm-hookd/Formula/duckterm-hookd.rb in the (private) DuckTerm
# repo; a copy is published to ducksee/homebrew-tap. Release assets are
# static binaries published to the public ducksee/duckterm-hookd-releases
# repo (the main repo is private — brew can't fetch private release assets).
#
# Release flow: ./build-all.sh → pack tarballs (+LICENSE) → gh release create
# on ducksee/duckterm-hookd-releases → update sha256s here → push to tap.
#
class DucktermHookd < Formula
  desc "Daemon bridging Claude Code / Codex hooks to the DuckTerm mobile app"
  homepage "https://github.com/ducksee/duckterm-hookd-releases"
  version "0.3.7"
  license :cannot_represent # proprietary (see package LICENSE)

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_darwin-arm64.tar.gz"
      sha256 "30c1a2036398d151c93bea3bb2fce4ad3bfb1e177eb81bf2765bb91246cebfa0"
    else
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_darwin-amd64.tar.gz"
      sha256 "3b88346adf52fc98d70eaf50f28e86e524cd1f0eaf66303280eecf002037c12e"
    end
  end

  on_linux do
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_linux-arm64.tar.gz"
      sha256 "243220c99495d063e44ff5ba43121e79c385a24f765162c14716f820a727e85b"
    else
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_linux-amd64.tar.gz"
      sha256 "6a2dd6d51f324f02ac39f2c74e6aec258580f46975cd52e554a50facdba071f0"
    end
  end

  def install
    bin.install "duckterm-hookd"
  end

  def caveats
    <<~EOS
      duckterm-hookd is a daemon. After install, choose ONE pairing method
      (QR and token pairing are alternatives; do not run both):

        duckterm-hookd pair --qr                      # scan in the DuckTerm app (easiest)
        # or:  duckterm-hookd pair --token <token> --user <account-id>
                                                       # DuckTerm app → Settings → Agent Hooks
        duckterm-hookd install                        # wire agent hooks
        brew services start duckterm-hookd

      Check version, pairing, and installed-hook state anytime:
        duckterm-hookd status

      Starting the service before pairing is safe — it waits and retries
      with backoff until you pair.

      The `install` step is non-destructive — it appends entries to
      ~/.claude/settings.json and ~/.codex/hooks.json without removing
      existing hooks. `duckterm-hookd uninstall` filters out only its own
      entries.

      Upgrade (one command — refreshes the tap Homebrew won't auto-pull,
      upgrades, and restarts the service):
        duckterm-hookd upgrade

      The Web control panel updates independently and does not restart hookd:
        duckterm-hookd ui check
        duckterm-hookd ui upgrade

      The control panel starts locally at http://127.0.0.1:20080. Expose it
      to a trusted LAN, or return it to local-only, without restarting hookd:
        duckterm-hookd config --lan --reload
        duckterm-hookd config --local --reload

      Uninstall (removes only DuckTerm's own hook entries, then the binary):
        duckterm-hookd uninstall && brew services stop duckterm-hookd && brew uninstall duckterm-hookd
    EOS
  end

  service do
    run [opt_bin/"duckterm-hookd", "serve"]
    keep_alive true
    log_path var/"log/duckterm-hookd.log"
    error_log_path var/"log/duckterm-hookd.log"
    working_dir var
  end

  test do
    assert_match "duckterm-hookd", shell_output("#{bin}/duckterm-hookd version")
    assert_match "127.0.0.1:20080", shell_output("#{bin}/duckterm-hookd config --json")
  end
end
