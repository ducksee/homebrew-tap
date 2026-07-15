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
  version "0.3.3"
  license :cannot_represent # proprietary (see package LICENSE)

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_darwin-arm64.tar.gz"
      sha256 "00f0025e2a9339b87afcfc7afc193ed9043adffcea837b1486665377bf701cf0"
    else
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_darwin-amd64.tar.gz"
      sha256 "ed37cddd077ba3d4b2caccaf706b30ae153de14b2f0948dd21f39bf35b91b01a"
    end
  end

  on_linux do
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_linux-arm64.tar.gz"
      sha256 "c04e18d183795fefbdd0245a251a8b4496e7ffd605baec7402251ee413003aa5"
    else
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_linux-amd64.tar.gz"
      sha256 "8761b947c96a1baba94579adddb95fde963b3a0a34996cba6f18b6b017eaa08a"
    end
  end

  def install
    bin.install "duckterm-hookd"
  end

  def caveats
    <<~EOS
      duckterm-hookd is a daemon. After install:

        duckterm-hookd pair --qr                      # scan in the DuckTerm app (easiest)
        # or:  duckterm-hookd pair --token <token>    # DuckTerm app → Settings → Agent Hooks
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

      Upgrading (Homebrew won't restart a running service for you):
        brew upgrade duckterm-hookd && brew services restart duckterm-hookd

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
  end
end
