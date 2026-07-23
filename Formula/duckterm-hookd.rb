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
  version "0.5.3"
  license :cannot_represent # proprietary (see package LICENSE)

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_darwin-arm64.tar.gz"
      sha256 "14646ecea6c3c8e3447b9c5e2685128f07f33532e24c5ec479ff7adad0ba774b"
    else
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_darwin-amd64.tar.gz"
      sha256 "9a5f74a5328e2c3550fc044233e8000b924389b486367b431746e3a8db45a5a7"
    end
  end

  on_linux do
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_linux-arm64.tar.gz"
      sha256 "36cfcfe6555a9a4bc9daa4aa1bb48fe2f28c59ad8aae650ad38b3893e3441603"
    else
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_linux-amd64.tar.gz"
      sha256 "2b359a3d35dd5abcaa2cdfc9ec36c103e5c78b64f5fe3eb52f7b9e7c85fa62f9"
    end
  end

  def install
    bin.install "duckterm-hookd"
    libexec.install "duckterm-hookd-web.tar.gz" if File.exist?("duckterm-hookd-web.tar.gz")
  end

  def post_install
    bundled_ui = libexec/"duckterm-hookd-web.tar.gz"
    return unless bundled_ui.exist?

    system bin/"duckterm-hookd", "ui", "bootstrap", bundled_ui
  rescue StandardError => e
    opoo "Bundled Hookd Web UI was not installed: #{e}. Run `duckterm-hookd ui upgrade` to repair it."
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
