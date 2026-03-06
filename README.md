# clawd

用于保存可同步到 Gitee 的 OpenClaw 定制内容，默认不提交密钥和本地运行态数据。

## 推荐目录

- `config/openclaw.template.json`: 公开可同步的脱敏模板
- `skills/`: 技能定义
- `prompts/`: 系统提示和模板
- `memory/`: 可共享记忆（谨慎放隐私内容）
- `scripts/export-openclaw-template.ps1`: 从本机配置导出脱敏模板

## 导出脱敏模板

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\export-openclaw-template.ps1
```

默认读取 `~/.openclaw/openclaw.json`，输出到 `./config/openclaw.template.json`。

## 本地私有配置

真实配置继续保留在本机：

- `~/.openclaw/openclaw.json`

仓库内如需临时私有文件，可用：

- `config/openclaw.json`（已在 `.gitignore` 忽略）

## 推送到 Gitee

```powershell
git -C $HOME\clawd init -b main
git -C $HOME\clawd add .
git -C $HOME\clawd commit -m "init clawd workspace"
git -C $HOME\clawd remote add origin git@gitee.com:<your-name>/<your-repo>.git
git -C $HOME\clawd push -u origin main
```

如果你的 Git 版本不支持 `-b main`，可改为：

```powershell
git -C $HOME\clawd init
git -C $HOME\clawd branch -M main
```

## 安全更新源码（不动你的内容层）

`openclaw-cn` 源码仓库和你的内容分离：

- 你的内容：`~/clawd`、`~/.openclaw`
- 源码仓库：`C:\Users\32480\openclaw-cn`

执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\update-openclaw-source.ps1
```

该脚本会做：

- `git pull --ff-only`
- 仅当 `pnpm-lock.yaml` 变化时执行 `pnpm install`
- 最后继续用 `pnpm gateway:watch`
