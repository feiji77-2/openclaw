---
summary: "安装 OpenClaw — 安装脚本、npm/pnpm、从源码构建、Docker 等"
read_when:
  - 你需要快速入门之外的安装方式
  - 你想部署到云平台
  - 你需要更新、迁移或卸载
title: "安装"
---

# 安装

已经完成了[快速入门](/start/getting-started)？那你已经准备好了 — 本页面提供其他安装方式、平台特定说明和维护信息。

## 系统要求

- **[Node 22+](/install/node)**（[安装脚本](#安装方式)会在缺失时自动安装）
- macOS、Linux 或 Windows
- 仅从源码构建时需要 `pnpm`

<Note>
在 Windows 上，我们强烈建议在 [WSL2](https://learn.microsoft.com/zh-cn/windows/wsl/install) 下运行 OpenClaw。
</Note>

## 安装方式

<Tip>
**安装脚本**是安装 OpenClaw 的推荐方式。它可以一步完成 Node 检测、安装和初始配置。
</Tip>

<AccordionGroup>
  <Accordion title="安装脚本" icon="rocket" defaultOpen>
    下载 CLI，通过 npm 全局安装，并启动初始配置向导。

    <Tabs>
      <Tab title="macOS / Linux / WSL2">
        ```bash
        curl -fsSL https://clawd.org.cn/install.sh | bash
        ```
      </Tab>
      <Tab title="Windows (PowerShell)">
        ```powershell
        iwr -useb https://clawd.org.cn/install.ps1 | iex
        ```
      </Tab>
    </Tabs>

    就这样 — 脚本会自动处理 Node 检测、安装和初始配置。

    如果想跳过初始配置，只安装二进制文件：

    <Tabs>
      <Tab title="macOS / Linux / WSL2">
        ```bash
        curl -fsSL https://clawd.org.cn/install.sh | bash -s -- --no-onboard
        ```
      </Tab>
      <Tab title="Windows (PowerShell)">
        ```powershell
        & ([scriptblock]::Create((iwr -useb https://clawd.org.cn/install.ps1))) -NoOnboard
        ```
      </Tab>
    </Tabs>

    查看所有参数、环境变量和 CI/自动化选项，请参阅[安装脚本详解](/install/installer)。

  </Accordion>

  <Accordion title="npm / pnpm" icon="package">
    如果你已经有 Node 22+，并且想自行管理安装：

    <Tabs>
      <Tab title="npm">
        ```bash
        npm install -g openclaw-cn@latest
        openclaw-cn onboard --install-daemon
        ```

        <Accordion title="sharp 构建错误？">
          如果你全局安装了 libvips（macOS 上通过 Homebrew 安装较常见）导致 `sharp` 构建失败，可以强制使用预构建二进制文件：

          ```bash
          SHARP_IGNORE_GLOBAL_LIBVIPS=1 npm install -g openclaw-cn@latest
          ```

          如果看到 `sharp: Please add node-gyp to your dependencies`，可以安装构建工具（macOS: Xcode CLT + `npm install -g node-gyp`）或使用上述环境变量。
        </Accordion>
      </Tab>
      <Tab title="pnpm">
        ```bash
        pnpm add -g openclaw-cn@latest
        pnpm approve-builds -g        # 批准 openclaw-cn、node-llama-cpp、sharp 等
        openclaw-cn onboard --install-daemon
        ```

        <Note>
        pnpm 要求显式批准包含构建脚本的包。首次安装显示"Ignored build scripts"警告后，运行 `pnpm approve-builds -g` 并选择列出的包。
        </Note>
      </Tab>
    </Tabs>

  </Accordion>

  <Accordion title="从源码构建" icon="github">
    适用于贡献者或想从本地代码运行的用户。

    <Steps>
      <Step title="克隆并构建">
        克隆 [OpenClaw 仓库](https://github.com/openclaw/openclaw) 并构建：

        ```bash
        git clone https://github.com/openclaw/openclaw.git
        cd openclaw
        pnpm install
        pnpm ui:build
        pnpm build
        ```
      </Step>
      <Step title="链接 CLI">
        将 `openclaw-cn` 命令设为全局可用：

        ```bash
        pnpm link --global
        ```

        也可以跳过链接，在仓库内通过 `pnpm openclaw-cn ...` 运行命令。
      </Step>
      <Step title="运行初始配置">
        ```bash
        openclaw-cn onboard --install-daemon
        ```
      </Step>
    </Steps>

    更深入的开发工作流，请参阅[开发设置](/start/setup)。

  </Accordion>
</AccordionGroup>

## 其他安装方式

<CardGroup cols={2}>
  <Card title="Docker" href="/install/docker" icon="container">
    容器化或无头部署。
  </Card>
  <Card title="Nix" href="/install/nix" icon="snowflake">
    通过 Nix 声明式安装。
  </Card>
  <Card title="Ansible" href="/install/ansible" icon="server">
    自动化批量部署。
  </Card>
  <Card title="Bun" href="/install/bun" icon="zap">
    通过 Bun 运行时使用 CLI。
  </Card>
</CardGroup>

## 安装后

验证一切正常运行：

```bash
openclaw-cn doctor         # 检查配置问题
openclaw-cn status         # 网关状态
openclaw-cn dashboard      # 打开浏览器管理界面
```

如果你需要自定义运行时路径，可以使用：

- `OPENCLAW_HOME` 设置基于主目录的内部路径
- `OPENCLAW_STATE_DIR` 设置可变状态的存储位置
- `OPENCLAW_CONFIG_PATH` 设置配置文件位置

详见[环境变量](/help/environment)了解优先级和完整说明。

## 故障排除：找不到 `openclaw-cn` 命令

<Accordion title="PATH 诊断与修复">
  快速诊断：

```bash
node -v
npm -v
npm prefix -g
echo "$PATH"
```

如果 `$(npm prefix -g)/bin`（macOS/Linux）或 `$(npm prefix -g)`（Windows）**不在**你的 `$PATH` 中，Shell 将无法找到全局 npm 二进制文件（包括 `openclaw-cn`）。

修复 — 将以下内容添加到你的 Shell 启动文件（`~/.zshrc` 或 `~/.bashrc`）：

```bash
export PATH="$(npm prefix -g)/bin:$PATH"
```

在 Windows 上，将 `npm prefix -g` 的输出添加到 PATH 中。

然后打开一个新终端（或在 zsh 中执行 `rehash` / 在 bash 中执行 `hash -r`）。
</Accordion>

## 更新 / 卸载

<CardGroup cols={3}>
  <Card title="更新" href="/install/updating" icon="refresh-cw">
    保持 OpenClaw 为最新版本。
  </Card>
  <Card title="迁移" href="/install/migrating" icon="arrow-right">
    迁移到新机器。
  </Card>
  <Card title="卸载" href="/install/uninstall" icon="trash-2">
    完全移除 OpenClaw。
  </Card>
</CardGroup>
