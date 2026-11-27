# 当前服务器版本与构建记录

维护服务器已于 **2026-11-27 10:06 UTC** 切换到 Bridge **1.122.0** 的 `fa20a82` 补丁。上一版构建 `fe64d77` 也报告 1.122.0；核对本次升级时可查看运行目录里的 `BUILD_COMMIT`。[线上部署记录](https://api.github.com/repos/zwthys-cyber/ccpocket/deployments/8107034824/statuses)

| 项目 | 当前值 |
| --- | --- |
| 已部署源码 | [fa20a82c9f9203305e1220fd9fec39f1c7827de4](https://github.com/zwthys-cyber/ccpocket/commit/fa20a82c9f9203305e1220fd9fec39f1c7827de4) |
| 构建分支 | [feat/bridge-gallery-reliability](https://github.com/zwthys-cyber/ccpocket/tree/feat/bridge-gallery-reliability) |
| 运行环境 | Linux x64，要求 Node.js 22.19.0+，构建使用 Node.js 24.22.1 |
| DeepSeek 模型 | 默认 `deepseek-flash[1m]`，可选 `deepseek-flash`、`deepseek-v4-pro`；设置 `DEEPSEEK_MODEL` 可修改默认模型 |
| 配套手机安装包 | [CC Pocket 1.140.9（构建 272）TrollStore 发布页](https://github.com/zwthys-cyber/ccpocket/releases/tag/trollstore/v1.140.9%2B272) |

## 这次修复了什么

- **重复气泡和时间错误。** Codex 会话恢复时，Bridge 按消息标识对齐实时消息和历史记录。有逐条确认时间时，插话使用自己的时间。同一次发送只显示一条，主动再次发送相同内容仍会保留两条。
- **图库删除和预览。** 多台手机同时操作时，删除按图片标识处理；重启后索引与磁盘文件保持一致。已配置密钥的服务要求 HTTP 图库列表和删除请求携带凭证。手机可以按需获取缩略图，已有原图地址继续有效。

## 下载服务器包

| 适用场景 | 下载 ZIP | ZIP 内的运行包 |
| --- | --- | --- |
| 新服务器，或现有生产依赖与本次构建有差异 | [完整 Linux x64 运行包](https://github.com/zwthys-cyber/ccpocket/releases/download/bridge-maintained/v1.122.0-fa20a82/deepseek-server-runtime.zip) | `bridge-deepseek-linux-x64.tar.gz`，内含生产依赖 |
| 已安装 1.122.0，且生产依赖与当前包一致 | [增量更新包](https://github.com/zwthys-cyber/ccpocket/releases/download/bridge-maintained/v1.122.0-fa20a82/deepseek-server-update.zip) | `bridge-deepseek-update.tar.gz`，复用旧运行目录的生产依赖 |

两个 ZIP 都包含 `BUILD_COMMIT` 和对应 tar 包的 `.sha256` 文件。发布页保留了本次构建的原始 ZIP，Actions 的临时产物于 2026-12-11（UTC）到期。[服务器发布页](https://github.com/zwthys-cyber/ccpocket/releases/tag/bridge-maintained/v1.122.0-fa20a82) · [完整包构建来源](https://github.com/zwthys-cyber/ccpocket/actions/runs/45976797469/artifacts/15188150362) · [增量包构建来源](https://github.com/zwthys-cyber/ccpocket/actions/runs/45976797469/artifacts/15187990707)

下载并校验完整包：

```bash
curl -fL --output deepseek-server-runtime.zip \
  'https://github.com/zwthys-cyber/ccpocket/releases/download/bridge-maintained/v1.122.0-fa20a82/deepseek-server-runtime.zip'
unzip deepseek-server-runtime.zip -d bridge-runtime
(cd bridge-runtime && sha256sum -c bridge-deepseek-linux-x64.tar.gz.sha256)
```

增量包适用于这次独立验证过的旧构建 `fe64d77`。其他安装应核对根目录的 `package.json`、`package-lock.json` 和 `packages/bridge/package.json` 与新包逐字节一致，并确认原有生产依赖完整；无法确认时请选择完整包。完整安装、服务切换和回退命令见[新服务器安装与更新指南](server-setup.zh-CN.md)。

## 验证记录

1. GitHub runner 完成全部 **79 个测试文件、2,733 项测试**，并通过 TypeScript 类型检查、生产编译、CLI 版本检查和启用鉴权的服务启动检查。[构建与测试](https://github.com/zwthys-cyber/ccpocket/actions/runs/45976797469)
2. 独立 runner 在旧运行包上覆盖增量包，确认编译文件与完整包一致，并验证旧图库原图、缩略图、鉴权、并发删除及重启后的状态。连续三次重建合成会话，稍后插入的消息只出现一次，再次发送的相同文字也保留。[独立升级验证](https://github.com/zwthys-cyber/ccpocket/actions/runs/45976993918)
3. 线上切换后已核对运行提交、服务健康、公网 HTTPS、鉴权和原有 DeepSeek 配置。构建和测试均在 GitHub 完成。[部署结果](https://api.github.com/repos/zwthys-cyber/ccpocket/deployments/8107034824/statuses)

## 如何重新构建

在 GitHub Actions 运行 **DeepSeek Server Build**，选择 `feat/bridge-gallery-reliability` 分支。也可通过 GitHub CLI 触发：

```bash
gh workflow run 426834290 -R zwthys-cyber/ccpocket --ref feat/bridge-gallery-reliability
gh run list -R zwthys-cyber/ccpocket --workflow 426834290 --branch feat/bridge-gallery-reliability
```

列表中可查看新任务 ID。成功后下载该任务的 `deepseek-server-runtime` 或 `deepseek-server-update`，核对包内的 `BUILD_COMMIT` 与目标提交一致。重新运行历史构建可从[本次工作流记录](https://github.com/zwthys-cyber/ccpocket/actions/runs/45976797469)进入。

- [DeepSeek 密钥配置与 Pro 模型选择](deepseek.zh-CN.md)
- [本次构建使用的 Bridge 环境变量](https://github.com/zwthys-cyber/ccpocket/tree/fa20a82c9f9203305e1220fd9fec39f1c7827de4/packages/bridge#configuration)
