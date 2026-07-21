# typed: false
# frozen_string_literal: true

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
  desc "Connect supported coding agents to the DuckTerm mobile app"
  homepage "https://github.com/ducksee/duckterm-hookd-releases"
  version "0.3.9"
  license :cannot_represent # proprietary (see package LICENSE)

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_darwin-arm64.tar.gz"
      sha256 "1a6ae2f1fbc1e3ccaa15a9f9b4996bfae8f8b38b3a2b405a9a7a90cba1720805"
    else
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_darwin-amd64.tar.gz"
      sha256 "47908d74e55d795aaa12024d17a75cf987471e7eb4bee4bd1cd8fd14b78091f1"
    end
  end

  on_linux do
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_linux-arm64.tar.gz"
      sha256 "ebce9ae005d2f192d4629d622c73fc3ef0649e50d659c5abf93e15b76cb1c012"
    else
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_linux-amd64.tar.gz"
      sha256 "78e38a27af4c84bf8e19fbc6f21a1231d4ca13b509d27a0b0773787359d58049"
    end
  end

  def install
    bin.install "duckterm-hookd"
  end

  def caveats
    if version >= Version.new("0.3.8")
      <<~EOS
        Finish setup:
          1. Open DuckTerm on iOS or Android → Settings → Agent notifications.
          2. Run:
               #{opt_bin}/duckterm-hookd setup --qr
          3. In the app, open Agent notifications → Verify.

        This pairs the machine, connects supported coding agents, and starts the
        background service. Running it again keeps the existing pairing.

        Check setup health anytime:
          #{opt_bin}/duckterm-hookd status

        Update Hookd (both names work):
          #{opt_bin}/duckterm-hookd update
          #{opt_bin}/duckterm-hookd upgrade

        The control panel is local at http://127.0.0.1:20080. On a trusted LAN:
          duckterm-hookd config --lan --reload

        Setup guide: https://dterm.limitwatch.app/setup
      EOS
    else
      <<~EOS
        Finish setup for this release:
          1. Run: #{opt_bin}/duckterm-hookd pair --qr
          2. Run: #{opt_bin}/duckterm-hookd install
          3. Run: brew services start duckterm-hookd

        In DuckTerm on iOS or Android, QR pairing is under
        Settings → Agent notifications → Pair by QR.

        Check setup health anytime:
          #{opt_bin}/duckterm-hookd status

        Setup guide: https://dterm.limitwatch.app/setup
      EOS
    end
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
