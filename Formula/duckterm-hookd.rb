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
  version "0.3.1"
  license :cannot_represent # proprietary (see package LICENSE)

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_darwin-arm64.tar.gz"
      sha256 "e557687c4100cff0b7521c46774145f2880d3f9a9a4dd4905a760eb9eae65804"
    else
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_darwin-amd64.tar.gz"
      sha256 "17e4f76cbcd724b8dab0799d147cfa0cd8a42e66372e41106a2f0bd79dd9c024"
    end
  end

  on_linux do
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_linux-arm64.tar.gz"
      sha256 "8d9f11f6e95b8891967981917d63011099e1e82cecea4b7bc09051c6234c397f"
    else
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_linux-amd64.tar.gz"
      sha256 "834a1319d2a9cb6f637dddb7026619b5e17e23b460be45c78689fae39c6eee44"
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

      Check pairing + install + connection state anytime:
        duckterm-hookd status

      Starting the service before pairing is safe — it waits and retries
      with backoff until you pair.

      The `install` step is non-destructive — it appends entries to
      ~/.claude/settings.json and ~/.codex/hooks.json without removing
      existing hooks. `duckterm-hookd uninstall` filters out only its own
      entries.

      Upgrading (Homebrew won't restart a running service for you):
        brew upgrade duckterm-hookd && brew services restart duckterm-hookd
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
