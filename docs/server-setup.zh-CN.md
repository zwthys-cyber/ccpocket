# 新服务器从零安装 CC Pocket（中文）

这份教程适合第一次使用云服务器的人。照顺序操作，最后你可以在手机上给 Codex 发任务，服务器负责执行。

**安装路线：GitHub 负责编译和测试，服务器只下载现成的运行包。** 不需要在服务器克隆 CC Pocket 源码，也不用运行 `npm ci`、`npm run bridge:build` 或测试套件。

## 先看懂这三样东西

| 名称 | 通俗解释 | 安装在哪里 |
| --- | --- | --- |
| CC Pocket App | 你操作和聊天的界面 | 手机 |
| Bridge | 把手机指令转交给编程代理的“中转站” | 服务器 |
| Codex CLI | 真正读取项目、执行任务的编程代理 | 服务器 |

下面先用 **Codex** 跑通。Claude 是另一种可选代理，不必一起安装。使用代理需要你自己的可用账号或 API 凭据，安装 CC Pocket 不会附送模型额度。

## 0. 准备服务器和账号

本教程按以下环境编写：

- **Ubuntu 24.04、x86_64 / amd64、systemd**。当前运行包不适用于 ARM、Alpine 或没有 systemd 的容器。
- 可以通过 SSH 登录的 `root` 账号。其他管理员账号可以先执行 `sudo -i`，再按下面操作。
- 一个 GitHub 账号，用来下载 Actions 构建包；一个可使用 Codex 的账号。
- 手机已经具备安装 CC Pocket 的条件；iPhone 的 TrollStore 包需要设备本身支持 TrollStore。

先在你自己的电脑终端执行，把“服务器公网IP”换成云厂商控制台显示的地址：

```bash
ssh root@服务器公网IP
```

后面的命令，除非明确标为“浏览器”或“手机”，都在这个 **服务器 SSH 终端** 中执行。不要复制 `root@主机名 #` 这样的提示符。

```bash
whoami
uname -m
ps -p 1 -o comm=
```

依次应看到 `root`、`x86_64`、`systemd`。如果不一致，先调整服务器环境，不要套用本教程的二进制包。

**新服务器有自己的 IP，不要照抄旧服务器的地址。** 可用下面的命令辅助查看出口公网 IP，再与控制台核对：

```bash
curl -4fsS https://api.ipify.org
echo
```

如果此时提示找不到 `curl`，先做下一步。服务器在 NAT 后面时，以云厂商提供的入站公网地址为准。

> 本教程为方便首次安装，服务使用 root 运行，因此连接者能让代理以 root 权限操作文件。只允许你信任的设备连接；不要把连接密钥发给别人。

## 1. 安装基础工具和 Node.js

Node.js 是 Bridge 的运行环境，不是编译工具。本教程固定使用与 GitHub 构建环境相同的 **24.22.1**。

先安装基础工具：

```bash
apt-get update && apt-get install -y git curl ca-certificates xz-utils gh openssl python3 nano
```

再复制下面**整个代码块**。它会下载 Node.js 官方二进制，核对校验值后安装；任意一步失败都会停止这个代码块：

```bash
(
  set -e
  test "$(uname -m)" = x86_64
  mkdir -p /root/ccpocket-downloads
  cd /root/ccpocket-downloads
  curl -fSLO https://nodejs.org/dist/v24.22.1/node-v24.22.1-linux-x64.tar.xz
  curl -fsS https://nodejs.org/dist/v24.22.1/SHASUMS256.txt -o node-shasums.txt
  grep ' node-v24.22.1-linux-x64.tar.xz$' node-shasums.txt | sha256sum -c -
  tar -xJf node-v24.22.1-linux-x64.tar.xz -C /usr/local --strip-components=1
  /usr/local/bin/node --version
  /usr/local/bin/npm --version
)
```

应看到校验结果 `OK` 和 Node.js 版本 `v24.22.1`。不要用 Ubuntu 仓库里可能较旧的 Node.js 替代后直接忽略版本错误。

## 2. 安装并登录 Codex

按 [OpenAI 官方安装说明](https://learn.chatgpt.com/docs/cli) 安装已经编译好的 Codex CLI：

```bash
curl -fsSL https://chatgpt.com/codex/install.sh -o /root/ccpocket-downloads/codex-install.sh &&
  sh /root/ccpocket-downloads/codex-install.sh
export PATH="/root/.local/bin:$PATH"
codex --version
```

服务器一般没有浏览器，使用设备码登录：

```bash
codex login --device-auth
```

终端会显示网址和一次性验证码。**在你自己的电脑或手机浏览器**打开终端给出的网址，登录并输入验证码；服务器终端保持打开，等它显示登录成功。

```bash
codex login status
```

若账号或组织未启用设备码登录，按 [官方认证说明](https://learn.chatgpt.com/docs/auth) 处理，或者使用自己的 API Key 认证。先把 Codex 登录问题解决，再继续安装 Bridge。

**这里登录的是 Codex，不是 GitHub。** 不要把验证码、`auth.json` 或 API Key 粘贴到 Issue、聊天记录或仓库。

## 3. 在 GitHub 生成运行包

在**浏览器**打开 [Bridge Security Build 工作流](https://github.com/zwthys-cyber/ccpocket/actions/workflows/bridge-security-build.yml)：

1. 登录有本仓库写入权限的 GitHub 账号。
2. 点击 **Run workflow（运行工作流）**。
3. 分支选 **main**，再点击运行。
4. 等这次任务变成绿色，且 `repair-verify-package` 作业成功。
5. 打开任务详情，底部应出现 `bridge-linux-x64-数字` 这个 Artifact（构建包）。

**没有绿色成功结果，或没有构建包，就不要继续部署。**

当前工作流会尝试在声明的版本范围内更新依赖，然后执行漏洞审计、Bridge 测试、类型检查、编译和运行包启动检查。检查通过后可能把更新后的锁文件提交回所选分支；它不是一个只读的打包按钮。因此只对你打算部署的 `main` 运行，不要随便选择旧备份标签。

运行包内已经包含 Bridge 程序和生产依赖。它是 **Linux 服务器端**，不是手机安装包，也不是源码 ZIP。

当前 Artifact 保存 **14 天**。以后装新服务器时如果旧包过期，重新运行此工作流即可；不要长期记住某一次任务的编号。仅下载的人需要仓库读取权限；没有运行权限时，请维护者代为生成构建包。

## 4. 登录 GitHub，下载运行包

公开仓库的源码可以匿名克隆，但 **下载 Actions 构建包仍需要 GitHub 登录**。在服务器执行：

```bash
gh auth login --hostname github.com --git-protocol https --web
```

按提示选择认证 Git，浏览器登录。看到类似：

```text
First copy your one-time code: XXXX-XXXX
Press Enter to open github.com in your browser...
```

就在自己的浏览器打开 <https://github.com/login/device>，输入**这次终端显示的**验证码并授权。服务器按回车继续；提示无法打开浏览器不影响你手动完成登录。

```bash
gh auth setup-git
gh auth status
```

然后列出 `main` 上最近成功的运行：

```bash
gh run list --repo zwthys-cyber/ccpocket \
  --workflow bridge-security-build.yml --branch main \
  --status success --limit 5
```

记下你在第 3 步生成的那次任务的 **ID 数字**。不要误选名为 `Test` 或 `Bridge Release` 的其他工作流。

下面整个代码块会让你输入 ID，下载构建包、核对文件校验值，然后以较低 CPU 优先级解压。**这里没有编译或安装 npm 依赖。**

```bash
(
  set -e
  read -rp "请输入成功的 Bridge Security Build 任务 ID: " CCPOCKET_RUN_ID
  [[ "$CCPOCKET_RUN_ID" =~ ^[0-9]+$ ]]
  test "$(gh run view "$CCPOCKET_RUN_ID" --repo zwthys-cyber/ccpocket \
    --json status,conclusion,headBranch \
    --jq '.status + ":" + .conclusion + ":" + .headBranch')" = "completed:success:main"
  mkdir -p /root/ccpocket-artifacts /root/ccpocket-releases /root/.config/ccpocket
  CCPOCKET_DOWNLOAD=$(mktemp -d "/root/ccpocket-artifacts/$CCPOCKET_RUN_ID.XXXXXX")
  gh run download "$CCPOCKET_RUN_ID" --repo zwthys-cyber/ccpocket \
    --name "bridge-linux-x64-$CCPOCKET_RUN_ID" --dir "$CCPOCKET_DOWNLOAD"
  cd "$CCPOCKET_DOWNLOAD"
  nice -n 19 sha256sum -c bridge-linux-x64.tar.gz.sha256
  CCPOCKET_COMMIT=$(tr -d '\r\n' < BUILD_COMMIT)
  [[ "$CCPOCKET_COMMIT" =~ ^[0-9a-f]{40}$ ]]
  CCPOCKET_RELEASE="/root/ccpocket-releases/$CCPOCKET_COMMIT"
  if [ ! -d "$CCPOCKET_RELEASE" ]; then
    CCPOCKET_STAGE=$(mktemp -d /root/ccpocket-releases/staging.XXXXXX)
    nice -n 19 tar -xzf bridge-linux-x64.tar.gz -C "$CCPOCKET_STAGE"
    test "$(cat "$CCPOCKET_STAGE/BUILD_COMMIT")" = "$CCPOCKET_COMMIT"
    test -f "$CCPOCKET_STAGE/packages/bridge/dist/cli.js"
    mv "$CCPOCKET_STAGE" "$CCPOCKET_RELEASE"
  fi
  test "$(cat "$CCPOCKET_RELEASE/BUILD_COMMIT")" = "$CCPOCKET_COMMIT"
  test -f "$CCPOCKET_RELEASE/packages/bridge/dist/cli.js"
  printf '%s\n' "$CCPOCKET_RELEASE" > /root/.config/ccpocket/next-release
  echo "下载完成，待安装版本：$CCPOCKET_COMMIT"
)
```

应看到 `bridge-linux-x64.tar.gz: OK` 和“下载完成”。如果报错，先解决错误，不要直接跳到下一步。

## 5. 生成手机连接密钥

先准备一个存放项目的目录：

```bash
mkdir -p /root/projects
```

下面会让你输入**新服务器的公网 IP**，例如 `203.0.113.10`（只是格式示例，不能直接使用）。只填 IPv4 地址，不填 `http://` 或端口：

```bash
python3 - <<'PY'
from pathlib import Path
import ipaddress
import secrets

directory = Path("/root/.config/ccpocket")
directory.mkdir(parents=True, exist_ok=True, mode=0o700)
directory.chmod(0o700)
config = directory / "bridge.env"
if config.exists():
    raise SystemExit("配置已存在，停止以保留原密钥。请用 nano 编辑已有文件。")
with open("/dev/tty") as terminal:
    print("请输入这台新服务器的公网 IPv4: ", end="", flush=True)
    address = str(ipaddress.IPv4Address(terminal.readline().strip()))
config.write_text(
    "BRIDGE_HOST=0.0.0.0\n"
    "BRIDGE_PORT=8765\n"
    "BRIDGE_API_KEY=" + secrets.token_hex(24) + "\n"
    "BRIDGE_PUBLIC_WS_URL=ws://" + address + ":8765\n"
    "BRIDGE_ALLOWED_DIRS=/root/projects\n"
    "BRIDGE_DISABLE_MDNS=1\n"
    "BRIDGE_DEMO_MODE=1\n"
)
config.chmod(0o600)
print("配置已保存；手机连接密钥已自动生成。")
PY
```

查看需要填进手机的地址和密钥：

```bash
sed -n 's/^BRIDGE_PUBLIC_WS_URL=/服务器地址：/p; s/^BRIDGE_API_KEY=/连接密钥：/p' \
  /root/.config/ccpocket/bridge.env
```

**这个连接密钥是 Bridge 的门锁，不是 OpenAI API Key，也不是 GitHub Token。** 地址和密钥会保存在服务器上，重启后不会改变。

本教程只允许从 `/root/projects` 选择项目。如果你要使用其他目录，用下面的命令打开配置，修改 `BRIDGE_ALLOWED_DIRS`，多个路径用逗号分隔：

```bash
nano /root/.config/ccpocket/bridge.env
```

`Ctrl+O`、回车保存，`Ctrl+X` 退出。**不要直接输入配置文件的路径来“打开”它**，那会变成执行文件并出现 `Permission denied`。

## 6. 设置后台服务和开机自启

后台服务的作用是：关掉 SSH 窗口后继续运行，服务器重启后自动启动。

下面是**新服务器首次安装**用的命令。已有同名服务时会停止，避免覆盖旧配置；不要在已经装好的服务器上重复执行。

```bash
(
  set -e
  test ! -e /root/.config/systemd/user/ccpocket-bridge.service
  test ! -d /root/.config/systemd/user/ccpocket-bridge.service.d
  CCPOCKET_RELEASE=$(cat /root/.config/ccpocket/next-release)
  test -f "$CCPOCKET_RELEASE/packages/bridge/dist/cli.js"
  ln -sfn "$CCPOCKET_RELEASE" /root/ccpocket-current
  mkdir -p /root/.config/systemd/user
  cat > /root/.config/systemd/user/ccpocket-bridge.service <<'UNIT'
[Unit]
Description=CC Pocket Bridge Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/root/ccpocket-current
Environment=PATH=/root/.local/bin:/usr/local/bin:/usr/bin:/bin
EnvironmentFile=/root/.config/ccpocket/bridge.env
ExecStart=/usr/local/bin/node /root/ccpocket-current/packages/bridge/dist/cli.js
Restart=on-failure
RestartSec=5
UMask=0077

[Install]
WantedBy=default.target
UNIT
  loginctl enable-linger root
  export XDG_RUNTIME_DIR=/run/user/0
  systemctl --user daemon-reload
  systemctl --user enable --now ccpocket-bridge
)
```

这里只运行下载包里的程序，不使用 `npx @ccpocket/bridge`，也不执行 `cli.js setup`。仓库内置的 Linux setup 会生成通过 npm 发布包启动的服务，可能与你刚下载的本分支版本不同。

## 7. 看服务是否启动成功

这一步只是几个轻量的状态查询，**不会执行测试、审计或编译**：

```bash
systemctl --user is-active ccpocket-bridge
systemctl --user is-enabled ccpocket-bridge
loginctl show-user root -p Linger
curl -fsS --max-time 5 http://127.0.0.1:8765/health
echo
```

应分别看到 `active`、`enabled`、`Linger=yes`，以及含有 `"status":"ok"` 的 JSON。它们说明 Bridge 在运行；**还不代表手机能连上，也不代表你的模型账号有可用额度**。

如果没有启动，先看日志：

```bash
journalctl --user -u ccpocket-bridge -n 80 --no-pager
```

不要为了排查启动错误，在小服务器上运行 `npm audit fix`、`npm ci` 或整套测试。

## 8. 让手机连接服务器

### 先处理网络

服务器服务监听 TCP `8765`。在云厂商控制台找到“安全组 / 防火墙”，允许你的连接来源访问此端口。若系统还启用了 UFW，也需要相应放行；不要直接关闭防火墙或把所有端口全部开放。

`ws://` 不加密；API Key 只负责认证。长期公网使用请采用 [Tailscale](https://tailscale.com/kb/1017/install) 私网，或配置带有效证书的 `wss://` 反向代理。直接使用公网 `ws://` 时，将访问来源限制为你信任的 IP。

如果改用 Tailscale，手机和服务器加入同一个网络，在 App 中填写服务器的 Tailscale IP；同时可修改配置中的 `BRIDGE_PUBLIC_WS_URL`。不需要把公网 `8765` 向所有人开放。

### 安装 App 并填写信息

1. 从 [本仓库 Releases](https://github.com/zwthys-cyber/ccpocket/releases?q=trollstore) 下载适合设备的包。iOS 的文件为 `CC-Pocket-TrollStore-unsigned.ipa`，需要支持 TrollStore 的设备；它不是 App Store 安装方式。
2. 打开 CC Pocket，添加服务器，选择手动填写连接信息。
3. 服务器地址填第 5 步输出的地址，例如 `ws://你的新服务器IP:8765`；API Key / 连接密钥填同一步生成的密钥。
4. 连接后选择 `/root/projects` 下的一个项目目录，再选择 **Codex**。

本教程设置了 `BRIDGE_DEMO_MODE=1`，日志二维码不包含密钥，避免日志泄露连接凭据。**首次连接请手动填地址和密钥，不要只扫码后认为认证已经配好。**

### 发出第一条任务

先在服务器放一个练习项目：

```bash
mkdir -p /root/projects/hello-ccpocket
git -C /root/projects/hello-ccpocket init
```

然后在手机选择该目录，创建 Codex 会话，发送：

> 请在当前目录创建 README.md，写一句“这是我通过 CC Pocket 发出的第一个任务”，先不要安装依赖。

看到回复和文件后，就完成了最初的使用流程。接下来可以把自己的项目克隆到 `/root/projects`；私有项目另外需要相应的 GitHub 读取权限。

## 日常最常用的命令

| 想做什么 | 在服务器执行 |
| --- | --- |
| 看是否运行 | `systemctl --user status ccpocket-bridge --no-pager` |
| 看最近日志 | `journalctl --user -u ccpocket-bridge -n 80 --no-pager` |
| 修改地址、目录等配置 | `nano /root/.config/ccpocket/bridge.env` |
| 修改配置后生效 | `systemctl --user restart ccpocket-bridge` |
| 暂时停止 | `systemctl --user stop ccpocket-bridge` |
| 再次启动 | `systemctl --user start ccpocket-bridge` |
| 查看手机连接密钥 | `sed -n 's/^BRIDGE_API_KEY=//p' /root/.config/ccpocket/bridge.env` |
| 看 Codex 是否登录 | `/root/.local/bin/codex login status` |

这里是**用户级 systemd 服务**，管理命令都有 `--user`。不要混用没有 `--user` 的同名服务命令。

## 以后怎么更新和回退

**更新：** 先在手机结束正在执行的任务，避免重启打断任务。重新完成第 3、4 步，得到一个在 GitHub 完成验证的新包。不要重新生成 `bridge.env`，否则手机保存的密钥会失效。

然后执行：

```bash
(
  set -e
  CCPOCKET_RELEASE=$(cat /root/.config/ccpocket/next-release)
  test -f "$CCPOCKET_RELEASE/packages/bridge/dist/cli.js"
  CCPOCKET_CURRENT=$(readlink -f /root/ccpocket-current)
  if [ "$CCPOCKET_CURRENT" = "$CCPOCKET_RELEASE" ]; then
    echo "当前已经是这个版本，无需更新。"
    exit 0
  fi
  printf '%s\n' "$CCPOCKET_CURRENT" > /root/.config/ccpocket/previous-release
  ln -sfn "$CCPOCKET_RELEASE" /root/ccpocket-current
  systemctl --user restart ccpocket-bridge
)
```

按第 7 步查看状态。如果新版启动异常，回到上一个运行包：

```bash
(
  set -e
  CCPOCKET_PREVIOUS=$(cat /root/.config/ccpocket/previous-release)
  test -f "$CCPOCKET_PREVIOUS/packages/bridge/dist/cli.js"
  ln -sfn "$CCPOCKET_PREVIOUS" /root/ccpocket-current
  systemctl --user restart ccpocket-bridge
)
```

这是 **Bridge 程序**的回退，不会撤销项目文件、代理会话或数据格式的变化。保留旧版本目录，确认新版可用后再考虑清理，不要随手删除仍在使用的版本。

如果你的旧安装服务直接指向 `/root/ccpocket` 或使用 `deployment.conf` 覆盖启动路径，它不会自动跟随本教程的 `ccpocket-current` 链接；请先检查实际路径，再迁移，不能直接套用此更新段：

```bash
systemctl --user show ccpocket-bridge -p ExecStart -p WorkingDirectory -p DropInPaths
```

## 遇到问题，先对照这里

| 现象 | 先检查什么 |
| --- | --- |
| `git/node/gh: command not found` | 第 1 步是否成功；不要跳过失败的下载或安装 |
| `Exec format error` / `GLIBC_… not found` | 是否是 Ubuntu 24.04 x86_64；ARM、Alpine 不能直接使用这个包 |
| GitHub 提示输入 Username、无法读取私有项目 | `gh auth login` 和 `gh auth setup-git`；本项目目前公开，私有项目仍需自己的访问权限 |
| 任务列表为空 | 第 3 步是否在 main 成功生成了包；手动运行需要仓库写入权限 |
| `artifact not found` / 包已过期 | Artifact 只保留 14 天，重新在 GitHub 生成；确认 ID 对应正确工作流 |
| Actions 报付款或额度问题 | 标准运行器在公开仓库免费，但账号付款异常仍可能限制任务；查看 GitHub Billing 和任务错误，不能保证改公开就一定恢复 |
| `Failed to connect to bus` | 确认是 SSH 登录的完整 systemd 主机；执行 `loginctl enable-linger root`，并检查 `/run/user/0`；必要时重新 SSH 登录。不要去容器里启动 systemd |
| 本机 health 正常、手机连接超时 | 云安全组、系统防火墙、地址和端口；手机不能填写 `127.0.0.1` |
| `Unauthorized`、连接后马上断开 | 手机里的 Bridge 密钥是否完整；不要错填 Codex 或 GitHub 的密钥 |
| 手机看不到项目目录 | 项目是否在 `BRIDGE_ALLOWED_DIRS` 里；修改配置后重启 Bridge |
| 手机能连，但 Codex 无法执行任务 | 第 2 步的 Codex 登录状态、账号额度、网络，以及服务日志；Bridge 健康不等于模型调用成功 |
| 配置文件路径输入后 `Permission denied` | 用 `nano 文件路径` 编辑；配置文件不是命令 |

## 给后续帮你安装的代理看的要求

可以直接把下面这段发给 Codex 或其他安装助手，并填入你自己确认的新 IP：

> 在新服务器安装 zwthys-cyber/ccpocket，先核对服务器公网 IP 为【填写新 IP】。按本仓库中文新服务器安装教程操作。依赖修复、审计、测试、编译和打包全部交给 GitHub Actions，服务器仅安装必要运行时、下载解压已验证产物、配置后台服务和做轻量状态查询。保留连接密钥和旧运行包，不在服务器执行 npm ci、npm audit fix、构建或测试套件。需要联网或系统权限时请求授权；不要公开我的认证文件或密钥。

## 参考

- [中文首页](../README.zh-CN.md)
- [实际构建工作流](../.github/workflows/bridge-security-build.yml)
- [Bridge 配置项](../packages/bridge/README.md#configuration)
- [OpenAI Codex CLI 安装](https://learn.chatgpt.com/docs/cli)与[认证说明](https://learn.chatgpt.com/docs/auth)
- [GitHub 构建包下载规则](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/download-workflow-artifacts)
- [Node.js 24.22.1 官方下载](https://nodejs.org/en/download/archive/v24.22.1)
