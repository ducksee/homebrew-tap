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
  version "0.2.1"
  license :cannot_represent # proprietary (see package LICENSE)

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_darwin-arm64.tar.gz"
      sha256 "98bbd5fbdc140efa1c13ba08deb91e77676793221bdc2110b6c66f665f564a3a"
    else
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_darwin-amd64.tar.gz"
      sha256 "2d4417ede4e23db24c9edfb8749d3edda9bb45cdb397d236f65bdb7354e6ee41"
    end
  end

  on_linux do
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_linux-arm64.tar.gz"
      sha256 "023a253af9f1c39ee2b0ee9570bbf6f0448f3b51655b198e11fac6fba16f0ff2"
    else
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_linux-amd64.tar.gz"
      sha256 "a895ddd02634cdc2a1374110142cff9c6251ae253a7b5a1678a3865bdd24ebb0"
    end
  end

  def install
    bin.install "duckterm-hookd"
  end

  def caveats
    <<~EOS
      duckterm-hookd is a daemon. After install:

        duckterm-hookd pair --token <pairing-token>   # from the DuckTerm app
        duckterm-hookd install                        # wire agent hooks
        brew services start duckterm-hookd

      Starting the service before pairing is safe — it waits and retries
      with backoff until you pair.

      The `install` step is non-destructive — it appends entries to
      ~/.claude/settings.json and ~/.codex/hooks.json without removing
      existing hooks. `duckterm-hookd uninstall` filters out only its own
      entries.
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
