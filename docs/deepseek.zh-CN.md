# 在 CC Pocket 中使用 DeepSeek

CC Pocket 的 Bridge 可以通过 [DeepSeek 官方 Anthropic 兼容接口](https://api-docs.deepseek.com/quick_start/agent_integrations/claude_code/)使用 DeepSeek。手机端沿用 **Claude** 会话入口，模型列表显示 DeepSeek 模型；流式消息、工具调用、权限确认和历史会话沿用现有机制。

## 编译和下载

本功能分支的编译、测试和启动检查由 GitHub Actions 的 **Test → bridge** 任务执行。在成功运行的页面下载 **bridge-package**，解压后得到 `ccpocket-bridge-1.90.0.tgz`（文件名随项目版本变化）。该包包含本分支编译后的 Bridge，不需要发布到 npm。

在实际部署机器安装，而不是在用于编辑代码的服务器执行：

```bash
npm install -g ./ccpocket-bridge-1.90.0.tgz
```

部署机器仍需满足 Bridge 的 Node.js 和 Claude Code 运行条件。手机已有客户端支持 Bridge 动态模型列表，因此无需为本次接入重新编译手机应用。

## 配置并启动

在实际运行 Bridge 的电脑或服务器配置：

```bash
export BRIDGE_CLAUDE_BACKEND=deepseek
export DEEPSEEK_API_KEY='替换成你自己的 DeepSeek API Key'
# 可选，默认为 deepseek-flash[1m]
export DEEPSEEK_MODEL='deepseek-flash[1m]'
ccpocket-bridge
```

密钥从 [DeepSeek 平台](https://platform.deepseek.com/)获取。它只保存在部署机器的环境中，不应提交到仓库或填入 PR；GitHub 编译无需密钥。启动命令也可用于 Windows PowerShell，但环境变量需改用 `$env:变量名='值'` 语法。

手机连接该 Bridge 后，新建会话时选择 **Claude**，模型选 `deepseek-flash[1m]`、`deepseek-flash` 或 `deepseek-v4-pro`。也支持通过 `DEEPSEEK_MODEL` 指定其他 DeepSeek 模型；该配置会成为模型列表第一项。模型是否可用取决于 DeepSeek API 和账号权限。

旧客户端保存的 Claude 模型选择会转换成 `DEEPSEEK_MODEL`，避免依赖 API 隐式映射到不同计费档位。Claude 特有的 effort 选择不会传给 DeepSeek。DeepSeek 模型的能力、上下文长度和计费以官方文档为准，不能假定支持 Claude 的全部功能。

## 后台服务

`ccpocket-bridge setup` 不会自动保存这三个 DeepSeek 环境变量。已有后台服务需要在其运行环境中配置，再重启服务；在终端 export 后重启系统服务不等于服务已经获得变量。

Linux 用户级 systemd 服务可以使用：

```bash
systemctl --user edit ccpocket-bridge
```

加入以下配置（替换密钥），保存后重启：

```ini
[Service]
Environment="BRIDGE_CLAUDE_BACKEND=deepseek"
Environment="DEEPSEEK_API_KEY=替换成你自己的密钥"
Environment="DEEPSEEK_MODEL=deepseek-flash[1m]"
```

```bash
systemctl --user daemon-reload
systemctl --user restart ccpocket-bridge
```

macOS launchd 服务则在 `~/Library/LaunchAgents/com.ccpocket.bridge.plist` 的 `EnvironmentVariables` 字典中添加同名字符串配置，重新加载服务。密钥属于本机敏感配置，注意配置文件访问权限。之后再次执行 `setup` 会重建服务配置，需要重新补充变量。

## 检查和切换

在与服务相同的环境中运行 `ccpocket-bridge doctor` 可以检查是否配置 DeepSeek 密钥。`DeepSeek configured; API key not verified` 只说明本地配置齐全，实际请求成功才能验证密钥、余额和模型权限。

该开关作用于此 Bridge 的全部 Claude 通道会话，包括恢复的历史会话。建议先新建会话验证；要同时使用 Anthropic 和 DeepSeek，可分别启动两个不同端口的 Bridge。Codex 会话不受影响。

移除 `BRIDGE_CLAUDE_BACKEND` 并重启 Bridge 即恢复原来的 Claude 后端。历史记录仍保存在原有 Claude 会话目录中。

CI 使用模拟密钥验证配置与 SDK 调用，再在 GitHub runner 上启动演示模式进行健康检查。它不调用付费 DeepSeek API，因此不代表已完成真实模型对话验证。
