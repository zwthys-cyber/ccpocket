# 在 CC Pocket 中使用 DeepSeek

更新日期：**2026-11-22**。当前维护服务器已升级到 **Bridge 1.119.0**，源码位于 [`upgrade/deepseek-bridge-1.119.0`](https://github.com/zwthys-cyber/ccpocket/tree/upgrade/deepseek-bridge-1.119.0)。[部署版本与构建证据](bridge-server-status.zh-CN.md)记录了具体提交和验证结果。

DeepSeek 使用云端 API，**无需在服务器安装模型或准备显卡**。Bridge 通过 [DeepSeek 官方 Anthropic 兼容接口](https://api-docs.deepseek.com/quick_start/agent_integrations/claude_code/)调用模型，手机端沿用 **Claude** 会话入口。服务器仍需 Node.js **22.19.0+** 和 Claude Code / Agent SDK 的运行条件；本次部署使用 Node.js **24.22.1**。

## 模型选择

| 手机显示的模型 | 用法 |
| --- | --- |
| `deepseek-flash[1m]` | 默认模型，通过 Claude Code 的长上下文模型标记使用 Flash |
| `deepseek-flash` | 显式选择 Flash |
| `deepseek-v4-pro` | 显式选择 Pro；已使用维护服务器的账号完成 API 响应验证 |

重新连接 Bridge，新建 **Claude** 会话，在模型列表中选择 **`deepseek-v4-pro`** 即可使用 Pro。要将 Pro 设为此 Bridge 的默认模型，把服务器环境文件中的 `DEEPSEEK_MODEL` 改为 `deepseek-v4-pro` 并重启服务。当前默认仍为 `deepseek-flash[1m]`。

该后端设置作用于此 Bridge 的全部 Claude 通道会话，包括恢复的历史会话；Codex 不受影响。旧客户端发送的 Claude 模型别名及 fallback model 会转换为 `DEEPSEEK_MODEL`。Claude 专有的 effort、fast mode、ultracode 选项不会传给 DeepSeek。模型可用性、能力和计费以 DeepSeek API 与账号权限为准。

## 获取运行包

小服务器只下载编译好的运行包，**不要在服务器执行依赖安装、审计、编译或测试套件**。1.119.0 完整运行包包含 Linux x64 生产依赖，不能直接复用旧版依赖来替代升级。

- [已验证的 Bridge Upgrade Build 运行](https://github.com/zwthys-cyber/ccpocket/actions/runs/45029554790)：下载 `bridge-upgrade-linux-x64-45029554790`，其中包含 `bridge-linux-x64.tar.gz`、校验文件和 `BUILD_COMMIT`。
- Artifact 保留 14 天。过期后在 [Bridge Security Build](https://github.com/zwthys-cyber/ccpocket/actions/workflows/bridge-security-build.yml)选择 `upgrade/deepseek-bridge-1.119.0`，`upstream_version` 留空后重新生成。
- 首次安装、GitHub 登录、校验、解压和回退步骤见[新服务器安装教程](server-setup.zh-CN.md)。使用本仓库产物；npm 上游发布包不包含本分支的 DeepSeek 配置开关。

## 填写 API Key

密钥从 [DeepSeek 平台](https://platform.deepseek.com/)获取。以下是 root 部署路径；其他账号应使用自己的绝对路径。

```bash
mkdir -p /root/.config/ccpocket
touch /root/.config/ccpocket/deepseek.env
chmod 700 /root/.config/ccpocket
chmod 600 /root/.config/ccpocket/deepseek.env
nano /root/.config/ccpocket/deepseek.env
```

填入下面三行，把占位文字替换为自己的密钥。已有文件只修改需要变更的值：

```ini
DEEPSEEK_API_KEY=替换成自己的DeepSeek密钥
BRIDGE_CLAUDE_BACKEND=deepseek
DEEPSEEK_MODEL=deepseek-flash[1m]
```

按 **Ctrl+O → 回车**保存，**Ctrl+X**退出。要默认使用 Pro，第三行改为 `DEEPSEEK_MODEL=deepseek-v4-pro`。

`DEEPSEEK_API_KEY` 用于模型调用；`bridge.env` 中的 `BRIDGE_API_KEY` 用于手机连接，两者不同。不要把真实密钥发到聊天、提交到 GitHub 或填入构建工作流。GitHub 编译不需要 DeepSeek 密钥。

## 后台服务

维护服务器使用**系统级** `ccpocket-bridge.service`。服务通过 drop-in 加载环境文件：

```bash
mkdir -p /etc/systemd/system/ccpocket-bridge.service.d
nano /etc/systemd/system/ccpocket-bridge.service.d/30-deepseek.conf
```

配置内容：

```ini
[Service]
EnvironmentFile=/root/.config/ccpocket/deepseek.env
```

保存后加载配置并重启。重启会中断正在执行的任务，先结束任务：

```bash
systemctl daemon-reload
systemctl restart ccpocket-bridge.service
systemctl is-active ccpocket-bridge.service
```

如果按[从零安装教程](server-setup.zh-CN.md)创建的是**用户级**服务，使用 `systemctl --user edit ccpocket-bridge` 添加相同的 `[Service]` 配置，再用 `systemctl --user daemon-reload`、`systemctl --user restart ccpocket-bridge`。不要同时启动两个占用同一端口的服务。

终端中的 `export` 不会自动传给 systemd。`cli.js setup` 也不会自动保存这三个 DeepSeek 变量，且可能重建为通过 npm 启动的服务。现有产物部署应保留原服务的 `ExecStart`、监听地址和配置文件。

## 检查与回退

轻量检查包括服务状态、`/health`、`/version` 和手机模型列表。服务监听了特定地址时，请向该地址查询；手机不能使用服务器的 `127.0.0.1`。

- `/version` 应返回 `1.119.0`；`/health` 应有 `status: ok`、`auth: required`。
- 手机重新连接后应出现上面的三个 DeepSeek 模型；首次验证建议新建会话。
- 在与服务相同的环境中运行 `doctor`，`DeepSeek configured; API key not verified` 只表示本地已配置密钥，不验证 API 余额或模型权限。
- 维护服务器已验证 Flash、Pro 的实际 API 响应，升级后也验证了模型列表、公网 TLS 和 WebSocket 鉴权。GitHub CI 使用模拟密钥，本身不调用付费 API。

切回普通 Claude 后端时移除 `BRIDGE_CLAUDE_BACKEND` 并重启，按原有方式配置 Claude 认证。要同时使用 Anthropic 和 DeepSeek，可分别部署不同端口的 Bridge。

程序回退按[安装教程的更新和回退章节](server-setup.zh-CN.md#以后怎么更新和回退)操作，保留 DeepSeek 环境文件、手机连接密钥和旧运行目录。程序回退不会撤销项目文件或历史数据的变化。
