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
  version "0.5.11"
  license :cannot_represent # proprietary (see package LICENSE)

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_darwin-arm64.tar.gz"
      sha256 "bcff7d7be185bf62c7ecd0d49cf070e08009dc65f94d1ccca2a84a3d998df92d"
    else
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_darwin-amd64.tar.gz"
      sha256 "0bd60317c8c76bb1bf5d407f1acaff11083230a04813ef11b4ec1f7a8109cdc3"
    end
  end

  on_linux do
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_linux-arm64.tar.gz"
      sha256 "4b37d4db7b0530001ef4868582db2e08b860489a81e267838196607a055cf6c2"
    else
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_linux-amd64.tar.gz"
      sha256 "5de14f556bbcd7387c889a62a1c515195d4f6bd65e374840ca4bb81b54ce20a2"
    end
  end

  def install
    bin.install "duckterm-hookd"
    bin.install_symlink "duckterm-hookd" => "dhook"
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
          2. Run: #{opt_bin}/duckterm-hookd hook install
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
    # Homebrew derives this from the active prefix. Do not guess Intel/Apple
    # Silicon paths in Hookd or freeze launchd's system-only default PATH.
    environment_variables PATH: std_service_path_env,
                          DUCKTERM_HOOKD_LOG_PATH: "#{var}/log/duckterm-hookd.log"
    # Hookd owns bounded rotation. launchd must not keep a second append-only
    # descriptor to the same file while the process renames it.
    log_path "/dev/null"
    error_log_path "/dev/null"
    working_dir var
  end

  test do
    assert_match "duckterm-hookd", shell_output("#{bin}/duckterm-hookd version")
    assert_match "duckterm-hookd", shell_output("#{bin}/dhook version")
    assert_match "127.0.0.1:20080", shell_output("#{bin}/duckterm-hookd config --json")
  end
end
