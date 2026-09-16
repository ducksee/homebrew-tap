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
  version "0.5.18"
  license :cannot_represent # proprietary (see package LICENSE)

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_darwin-arm64.tar.gz"
      sha256 "5f741339eca316c86f4d04d9d8a10a252af9feadb22cbdfae695765fb2ccf2f1"
    else
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_darwin-amd64.tar.gz"
      sha256 "86477868fc7fa1872626bb77d35b2fcc368921d5f510737c0f3da699133a6dd4"
    end
  end

  on_linux do
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_linux-arm64.tar.gz"
      sha256 "c1730ae34de07a58ee15fa32801fe9144443919ee8e478510d83a898bdfadb48"
    else
      url "https://github.com/ducksee/duckterm-hookd-releases/releases/download/v#{version}/duckterm-hookd_linux-amd64.tar.gz"
      sha256 "5b21150546a051acedf16bc975d406e18d50b3eac07a018f417068c92661b266"
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
          #{opt_bin}/duckterm-hookd doctor

        macOS may ask duckterm-hookd for Documents, Desktop, or Downloads
        access. A Homebrew upgrade installs a new Cellar path, so that
        grant does not follow the binary. If project browse hangs on those
        folders, click Allow on the system dialog, or add the hookd binary
        under System Settings → Privacy & Security → Files and Folders.

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
