# fredgnr Homebrew tap

通过 Homebrew 安装和升级 [gopls-mcp-proxy](https://github.com/fredgnr/gopls-mcp-proxy)。配方使用 GitHub Release 的预编译二进制，支持 macOS / Linux 的 arm64 和 amd64，并通过 SHA-256 校验下载内容。

## 安装与升级

```sh
brew install fredgnr/tap/gopls-mcp-proxy

brew update
brew upgrade fredgnr/tap/gopls-mcp-proxy
```

配方仅安装代理，不声明或自动安装 Go、gopls 依赖。使用 gopls 后端时，请自行安装和配置 gopls 及其需要的 Go 工具链。MCP 配置中的 `command` 使用下面命令输出的稳定路径，工作目录设置为实际 Go 项目目录：

```sh
echo "$(brew --prefix)/bin/gopls-mcp-proxy"
```

Apple Silicon Mac 的常见路径是 `/opt/homebrew/bin/gopls-mcp-proxy`。不要填写包含版本号的 `Cellar` 路径。默认启动无需 `args`；已有代理选项可以保留。升级后让 MCP 宿主重新建立连接，新启动的代理进程才会使用新版。

配方直接安装代理二进制，不创建 gopls 链接，也不修改 `PATH`。默认查找先检查代理实际可执行文件的同目录，再搜索继承的 `PATH`；公共命令符号链接所在目录不会自动参与查找。请把自行安装的 Go 和 gopls 所在绝对目录加入 **MCP 宿主进程**的 `PATH`。GUI 启动的 IDE 可能不继承终端配置，需要单独设置。

使用特定 gopls 时，可保留代理选项并显式指定 `-- /absolute/path/to/gopls mcp`；gopls 所需的 Go 工具链仍需在宿主环境中可用。

已安装早期 `v0.7.0` 配方的用户，执行上面的升级命令可更新到 `0.7.0_1` 包修订，替换旧的依赖绑定。代理二进制没有变化，`--version` 仍显示 `v0.7.0`；升级前请配置好宿主的工具路径。

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

本 tap 的 GitHub Actions 在四个原生平台执行样式检查、严格配方审计、无依赖安装、真实 gopls MCP 冒烟测试和卸载验证：`macos-15`、`macos-15-intel`、`ubuntu-24.04`、`ubuntu-24.04-arm`。`brew test` 验证代理自身，无需安装 Go/gopls。CI 单独准备 Go 和 gopls，验证用户 `PATH` 中的默认后端、显式后端路径、`initialize`、`tools/list` 和 stdin EOF 后退出；测试工具不属于配方依赖。这些检查不代替主仓库的完整协议及刷新测试，也不代表实际 IDE 已验收。

```sh
brew style fredgnr/tap/gopls-mcp-proxy
brew audit --strict --formula fredgnr/tap/gopls-mcp-proxy
brew test fredgnr/tap/gopls-mcp-proxy
```

主仓库目前未声明许可证，因此配方未添加推定的 `license`。本 tap 不属于 `homebrew/core`。
