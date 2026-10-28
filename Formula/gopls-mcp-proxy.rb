class GoplsMcpProxy < Formula
  desc "Refresh MCP stdio backends when workspace inputs change"
  homepage "https://github.com/fredgnr/gopls-mcp-proxy"
  revision 1
  # Generated for 0.7.0 from the published release.

  on_macos do
    on_arm do
      url "https://github.com/fredgnr/gopls-mcp-proxy/releases/download/v0.7.0/gopls-mcp-proxy_v0.7.0_darwin_arm64.tar.gz"
      sha256 "72d174cf21a44a1222639e53f7463975fe40fe046a678eefa4175cd8735bb223"
    end
    on_intel do
      url "https://github.com/fredgnr/gopls-mcp-proxy/releases/download/v0.7.0/gopls-mcp-proxy_v0.7.0_darwin_amd64.tar.gz"
      sha256 "0e49d366f9f52ed46c09adcc7332728ef9b7707f452d72dbfe5e9828156aca9d"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/fredgnr/gopls-mcp-proxy/releases/download/v0.7.0/gopls-mcp-proxy_v0.7.0_linux_arm64.tar.gz"
      sha256 "2e35d7b247eb641560d6466f8d568056ac883f994b64cf817e3c3e322efd2b00"
    end
    on_intel do
      url "https://github.com/fredgnr/gopls-mcp-proxy/releases/download/v0.7.0/gopls-mcp-proxy_v0.7.0_linux_amd64.tar.gz"
      sha256 "9c2ea4d87c0c0258eb9c58d401475bb0d93a2e01070167807c7e4d038686015a"
    end
  end

  def install
    bin.install "gopls-mcp-proxy"
    doc.install "README.md", "BUILDINFO"
  end

  def caveats
    <<~EOS
      Go and gopls are not installed or configured by this formula.
      Install them yourself and make them available in your MCP host's PATH.
      Configure your MCP host to run:
        #{HOMEBREW_PREFIX}/bin/gopls-mcp-proxy
      Set its working directory to your Go project. To select a specific backend,
      use -- /absolute/path/to/gopls mcp; Go must still be available to gopls.
      Reconnect the MCP host after upgrading to start the new proxy version.
    EOS
  end

  test do
    require "open3"

    # The installed proxy must work without Go or gopls on PATH.
    ENV["PATH"] = testpath.to_s
    ["--version", "--help"].each do |argument|
      stdout, stderr, status = Open3.capture3(bin/"gopls-mcp-proxy", argument)
      assert_predicate status, :success?
      assert_empty stdout
      expected = (argument == "--version") ? "gopls-mcp-proxy v#{version}" : "Usage: gopls-mcp-proxy"
      assert_match expected, stderr
    end

    # A missing user-provided backend should fail with actionable guidance.
    workspace = testpath/"workspace"
    workspace.mkpath
    stdout, stderr, status = Open3.capture3(bin/"gopls-mcp-proxy", chdir: workspace)
    refute_predicate status, :success?
    assert_empty stdout
    assert_match "default gopls not found", stderr
    assert_match "install gopls or use -- program", stderr
  end
end
