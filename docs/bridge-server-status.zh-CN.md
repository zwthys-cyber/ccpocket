# 当前服务器版本与构建记录

核对日期：**2026-11-22**。本页记录维护服务器实际部署状态，不表示将来所有服务器都会自动更新。

## 当前版本

| 项目 | 当前值 |
| --- | --- |
| Bridge | **1.119.0**，已从 1.107.0 更新并重启 |
| 部署源码分支 | [`upgrade/deepseek-bridge-1.119.0`](https://github.com/zwthys-cyber/ccpocket/tree/upgrade/deepseek-bridge-1.119.0) |
| 已部署构建提交 | [`0f72e0f16cbfd4a6a8367d6aabf12bc0a104a585`](https://github.com/zwthys-cyber/ccpocket/commit/0f72e0f16cbfd4a6a8367d6aabf12bc0a104a585) |
| 上游 1.119.0 对应提交 | [`ee34eade0caa453aaa64706ddcb850bbc33d7910`](https://github.com/K9i-0/ccpocket/commit/ee34eade0caa453aaa64706ddcb850bbc33d7910) |
| 运行环境 | Linux x64，Node.js 24.22.1；该版要求 Node.js 22.19.0+ |
| DeepSeek 模型 | `deepseek-flash[1m]`、`deepseek-flash`、**`deepseek-v4-pro`** |
| 默认模型 | `deepseek-flash[1m]`；可通过 `DEEPSEEK_MODEL` 修改 |

首页和默认分支提供文档入口，服务器代码以本页列出的维护分支和构建提交为准。默认分支尚未合并该服务器升级代码。文档更新提交与已部署二进制的构建提交可以不同。

## 验证证据

[Bridge Upgrade Build：45029554790](https://github.com/zwthys-cyber/ccpocket/actions/runs/45029554790)在 GitHub runner 完成：

- **75 个测试文件、2674 项测试通过**。
- TypeScript 类型检查、Bridge 编译通过。
- 完整依赖与生产依赖审计通过。
- 编译后的 CLI 版本检查、运行包健康与鉴权启动检查通过。

[下载此运行的 Linux x64 产物](https://github.com/zwthys-cyber/ccpocket/actions/runs/45029554790/artifacts/14756792999)。产物包含完整生产依赖和校验信息，保留 14 天。

部署服务器只下载、核对校验、解压并切换到已验证的产物，没有运行 npm 依赖安装、编译或测试套件。切换后确认 `/version` 为 1.119.0、`/health` 正常且要求认证、公网 TLS 正常、WebSocket 鉴权与 DeepSeek 模型列表正常。

Flash 与 `deepseek-v4-pro` 均已在本次接入期间完成实际 DeepSeek API 响应验证；CI 的模拟测试与真实 API 验证分别记录，健康检查本身不代表模型调用一定成功。

## 保留的定制

升级同步了上游真实源码和依赖，并保留：

- DeepSeek 的 Claude 通道接入、模型别名映射、密钥检查和运行中模型切换。
- 原有的 Codex 历史图片索引流式读取修复。
- 原有的 Codex 额度重置接口及其手机协议扩展。
- 服务器现有的连接密钥、DeepSeek 环境文件、服务配置和历史记录。

## 获取后续构建

Artifact 过期后，运行默认分支已有的 [Bridge Security Build](https://github.com/zwthys-cyber/ccpocket/actions/workflows/bridge-security-build.yml)，**构建分支选 `upgrade/deepseek-bridge-1.119.0`，`upstream_version` 留空**。

```bash
gh workflow run bridge-security-build.yml \
  --repo zwthys-cyber/ccpocket \
  --ref upgrade/deepseek-bridge-1.119.0
```

等待绿色成功结果后再下载。此工作流重新生成的产物名为 `bridge-linux-x64-任务ID`，与本页这次升级运行的 `bridge-upgrade-linux-x64-任务ID` 前缀不同；内部运行包都名为 `bridge-linux-x64.tar.gz`。

升级到更高版本需要重新核对上游源码、处理兼容冲突并完成 GitHub 验证。不要仅改版本号，也不要使用不含本分支定制的 npm 包覆盖现有安装。

- [新服务器安装、更新与回退](server-setup.zh-CN.md)
- [DeepSeek 密钥配置与 Pro 模型选择](deepseek.zh-CN.md)
- [Bridge 环境变量](../packages/bridge/README.md#configuration)
