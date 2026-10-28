class GoplsMcpProxy < Formula
  desc "Refresh MCP stdio backends when workspace inputs change"
  homepage "https://github.com/fredgnr/gopls-mcp-proxy"
  version "0.7.0"

  depends_on "go"
  depends_on "gopls"

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
    libexec.install "gopls-mcp-proxy"
    # Default discovery follows the physical proxy path, so keep a private
    # sibling pointing at the dependency's stable opt path across upgrades.
    libexec.install_symlink formula_opt_bin("gopls")/"gopls"
    # Preserve an explicitly selected Go toolchain, with a fallback for GUI hosts.
    (bin/"gopls-mcp-proxy").write_env_script libexec/"gopls-mcp-proxy",
                                          PATH: "$PATH:#{formula_opt_bin("go")}"
    doc.install "README.md", "BUILDINFO"
  end

  def caveats
    <<~EOS
      Configure your MCP host to run:
        #{HOMEBREW_PREFIX}/bin/gopls-mcp-proxy
      Set its working directory to your Go project. The default backend is the
      Homebrew gopls dependency; use -- /absolute/path/to/gopls mcp to override it.
      Reconnect the MCP host after upgrading to start the new proxy version.
    EOS
  end

  test do
    require "json"
    require "open3"
    require "timeout"

    # Exercise the public wrapper without a Homebrew bin directory on PATH.
    ENV["PATH"] = "/usr/bin:/bin"
    ENV["GOWORK"] = "off"
    ENV["GOTOOLCHAIN"] = "local"
    ENV["GOPROXY"] = "off"
    ENV["GOSUMDB"] = "off"
    (testpath/"go.mod").write "module example.com/homebrew-smoke\n\ngo 1.25.0\n"
    (testpath/"main.go").write "package main\n\nfunc main() {}\n"

    stdout, stderr, status = Open3.capture3(bin/"gopls-mcp-proxy", "--version")
    assert_predicate status, :success?
    assert_empty stdout
    assert_match "gopls-mcp-proxy v#{version}", stderr

    # Diagnostic writes must not become watched project inputs.
    input, output, process = Open3.popen2(bin/"gopls-mcp-proxy", "--exclude", "proxy.log",
                                        err: (testpath/"proxy.log").to_s)
    input.sync = true
    send_message = lambda do |message|
      input.puts JSON.generate(message.merge(jsonrpc: "2.0"))
    end
    receive_result = lambda do |id|
      loop do
        line = output.gets
        raise "Proxy closed stdout before response #{id}" unless line

        message = JSON.parse(line)
        if message["method"] == "roots/list" && message.key?("id")
          send_message.call(id: message["id"], result: {
            roots: [{ uri: "file://#{testpath.realpath}", name: "homebrew-smoke" }],
          })
        elsif message.key?("method") && message.key?("id")
          send_message.call(id: message["id"], error: { code: -32601, message: "Method not found" })
        elsif message["id"] == id
          assert_nil message["error"], "MCP error: #{message}"
          break message.fetch("result")
        end
      end
    end

    begin
      Timeout.timeout(60) do
        send_message.call(id: 1, method: "initialize", params: {
          protocolVersion: "2025-11-25",
          clientInfo:      { name: "homebrew-smoke", version: "1" },
          capabilities:    { roots: { listChanged: false } },
        })
        initialization = receive_result.call(1)
        assert_match "gopls", initialization.fetch("serverInfo").fetch("name")
        send_message.call(method: "notifications/initialized")
        send_message.call(id: 2, method: "tools/list", params: {})
        assert_predicate receive_result.call(2).fetch("tools"), :any?
        input.close
        assert process.join(15), "Proxy did not exit after stdin EOF"
        assert_predicate process.value, :success?
      end
    ensure
      input.close unless input.closed?
      unless process.join(10)
        begin
          Process.kill("TERM", process.pid)
        rescue Errno::ESRCH
          nil
        end
        unless process.join(10)
          begin
            Process.kill("KILL", process.pid)
          rescue Errno::ESRCH
            nil
          end
          assert process.join(5), "Proxy could not be reaped after SIGKILL"
        end
      end
      output.close
      warn (testpath/"proxy.log").read unless process.value.success?
    end
  end
end
