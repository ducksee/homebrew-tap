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
  version "0.3.6"
  license :cannot_represent # proprietary (see package LICENSE)

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_darwin-arm64.tar.gz"
      sha256 "bcc1ae159ef7ed9f036736035c1a0a73f4e1d5840c75cd35ebf2d85cfe19e0a3"
    else
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_darwin-amd64.tar.gz"
      sha256 "ddb480e2191d3c8ef7d4775d1a5fa49a877e5df9ee7bf02ebff642cf421466e1"
    end
  end

  on_linux do
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_linux-arm64.tar.gz"
      sha256 "93977ecea15a5e8af9978dd2d4653aa0b729b9be8de6a259323402c36e67dbb7"
    else
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_linux-amd64.tar.gz"
      sha256 "a1491e578b5081640ac47891b274ffbb33a800a3389b00469a457ce9c6662605"
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
