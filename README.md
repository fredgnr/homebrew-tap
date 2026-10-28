# fredgnr Homebrew tap

通过 Homebrew 安装和升级 [gopls-mcp-proxy](https://github.com/fredgnr/gopls-mcp-proxy)。配方使用 GitHub Release 的预编译二进制，支持 macOS / Linux 的 arm64 和 amd64，并通过 SHA-256 校验下载内容。

## 安装与升级

```sh
brew install fredgnr/tap/gopls-mcp-proxy

brew update
brew upgrade fredgnr/tap/gopls-mcp-proxy
```

安装会同时安装 Homebrew 的 `gopls` 和 Go 工具链。MCP 配置中的 `command` 使用下面命令输出的稳定路径，工作目录设置为实际 Go 项目目录：

```sh
echo "$(brew --prefix)/bin/gopls-mcp-proxy"
```

Apple Silicon Mac 的常见路径是 `/opt/homebrew/bin/gopls-mcp-proxy`。不要填写包含版本号的 `Cellar` 路径。默认启动无需 `args`；已有代理选项可以保留。升级后让 MCP 宿主重新建立连接，新启动的代理进程才会使用新版。

配方将真实代理放在私有 `libexec` 目录，同目录的 `gopls` 链接指向 Homebrew gopls 的稳定 `opt` 路径，因此默认后端查找不依赖宿主的 Homebrew `PATH`。入口脚本将 Homebrew Go 的稳定路径追加到继承的 `PATH`，为 GUI 宿主提供回退，并保留已有 Go 工具链的优先级。使用特定 gopls 时，可保留代理选项并显式指定 `-- /absolute/path/to/gopls mcp`。

从 `go install` 或手动下载迁移前，检查重复安装，并把 MCP 配置中的旧代理路径改为上述 Homebrew 路径：

```sh
type -a gopls-mcp-proxy
```

卸载代理不会删除项目、MCP 配置或手动安装的程序：

```sh
brew uninstall fredgnr/tap/gopls-mcp-proxy
# 不再使用本 tap 中任何软件时：
brew untap fredgnr/tap
```

## 维护与验证

`Formula/gopls-mcp-proxy.rb` 由[主仓库的 Homebrew 模板与发布脚本](https://github.com/fredgnr/gopls-mcp-proxy/tree/main/scripts/homebrew)生成。发布约定、跨仓库凭证和失败重试方式见[主仓库 Homebrew 维护文档](https://github.com/fredgnr/gopls-mcp-proxy/blob/main/docs/homebrew-release.md)。不要手动修改某个已发布版本的附件或校验值；程序变更应发布新版本。

本 tap 的 GitHub Actions 在四个原生平台执行样式检查、严格配方审计、安装、真实 gopls MCP 冒烟测试和卸载验证：`macos-15`、`macos-15-intel`、`ubuntu-24.04`、`ubuntu-24.04-arm`。冒烟测试验证版本输出、精简 `PATH` 下的默认后端发现、`initialize`、`tools/list` 和 stdin EOF 后退出；它不代替主仓库的完整协议及刷新测试，也不代表实际 IDE 已验收。

```sh
brew style fredgnr/tap/gopls-mcp-proxy
brew audit --strict --formula fredgnr/tap/gopls-mcp-proxy
brew test fredgnr/tap/gopls-mcp-proxy
```

主仓库目前未声明许可证，因此配方未添加推定的 `license`。本 tap 不属于 `homebrew/core`。
