# CC Pocket

> 本仓库由 `zwthys-cyber` 维护。中文安装、TrollStore 和服务器连接说明请优先阅读
> [中文首页](README.md)。

**Your agents. In your pocket.**

Codex and Claude, with a chat UI made for your phone. Start a task, approve the next
step, and review the result. Pick up the same work on your tablet or Mac.

[Explore CC Pocket](https://zwthys-cyber.github.io/ccpocket/install/) · Free to use · Open source

[日本語版 README](README.ja.md) | [简体中文版 README](README.zh-CN.md) | [한국어 README](README.ko.md)

<p align="center">
  <img src="docs/images/screenshots.png" alt="CC Pocket screenshots" width="800">
</p>

## Install

**CC Pocket 1.140.10 (273)** · Install the [TrollStore IPA for iPhone and iPad](https://github.com/zwthys-cyber/ccpocket/releases/download/trollstore/v1.140.10%2B273/CC-Pocket-TrollStore-unsigned.ipa) on a device that supports TrollStore. [Release notes and SHA-256](https://github.com/zwthys-cyber/ccpocket/releases/tag/trollstore/v1.140.10%2B273)

For a new Linux x64 server, download the [complete Bridge 1.122.0 runtime](https://github.com/zwthys-cyber/ccpocket/releases/download/bridge-maintained/v1.122.0-fa20a82/deepseek-server-runtime.zip). The [Chinese installation guide](docs/server-setup.zh-CN.md) covers Node.js 22.19.0 or later, configuring the service and connecting your phone. [Bridge release and update packages](https://github.com/zwthys-cyber/ccpocket/releases/tag/bridge-maintained/v1.122.0-fa20a82)

Developers building another client platform can follow the [development instructions](#development).

## Free to Use

CC Pocket is free to use. If it helps your workflow, please consider becoming a Supporter in the app. Supporter purchases help cover development and AI tooling costs.

New to mobile coding agents? See [How to run Codex from iPhone or Android](https://zwthys-cyber.github.io/ccpocket/how-to-run-codex-from-iphone-android/).

## What You Can Do

- **Chat first.** Each session is a room for prompts, replies, approvals, and questions. Markdown, voice input, and image attachments make it easier to give direction on mobile.
- **Continue across devices.** Resume sessions from the CLI or app on your phone, tablet, or Mac. Larger screens show chat, files, and Git changes side by side.
- **Keep your place on weak networks.** Outgoing messages wait while you are offline and resend after reconnecting. Missed streaming updates are recovered. New agent requests need a connection.
- **Create and preview media.** Generate images with Codex Imagegen, open results in chat, and play video or audio files in the app.
- **Review and ship.** Browse files, inspect code and image diffs, stage changes, commit, push, or revert. Use git worktrees to separate parallel tasks.
- **Use your own machines.** Agents run on your Mac, Linux, or Windows host through the Bridge Server. Connect by QR code, saved host, or Tailscale; manage the Bridge over SSH.

## Why Fork CC Pocket?

CC Pocket is MIT licensed so you can treat it as a starting point for your own
agent workflow, not only as a finished app.

- Build an internal client that combines Codex or Claude with your team's Jira,
  Linear, GitHub, or private REST APIs.
- Remove surfaces you do not need and keep a focused app for your daily workflow.
- Reuse the Bridge sync layer, approval flow, prompt history, git operations,
  file browsing, and image/diff viewers instead of rebuilding them from scratch.
- Keep compatibility with the local agent tools and their session history while
  adding workflow-specific GUI features that are easier to use than prompts or MCP.
- Extend desktop support. macOS, Linux, and Windows builds are available today;
  Linux and Windows remain experimental because the project does not have the
  same continuous verification coverage for those environments.

For a deeper implementation overview, see the
[technical stack page](https://zwthys-cyber.github.io/ccpocket/architecture/) or the
[agent-readable Markdown](https://zwthys-cyber.github.io/ccpocket/architecture/stack.md).

## How It Works

CC Pocket has two parts:

```text
CC Pocket app  <->  Bridge Server on your machine  <->  Codex / Claude
```

The app is the interface you use. The Bridge Server runs locally on the machine that
has access to your projects, shell, git repository, and agent CLI. Your code stays
on your own machine instead of moving into a hosted IDE.

## Remote Access

On the same network, connect with the QR code, mDNS discovery, or a manual
`ws://` / `wss://` URL.

For access away from home or the office, Tailscale is the recommended setup:

1. Install [Tailscale](https://tailscale.com/) on your host machine and phone.
2. Join the same tailnet.
3. Connect to `ws://<host-tailscale-ip>:8765` from CC Pocket.

For an always-on host, the Bridge Server can also be registered as a background service:

```bash
node packages/bridge/dist/cli.js setup --host 0.0.0.0 --port 8765
```

Service setup supports macOS launchd and Linux systemd.
For Bridge flags and persisted service settings such as `BRIDGE_ALLOWED_DIRS`,
see the [Bridge package README](packages/bridge/README.md#configuration).

## Notes

- Claude sessions use `ANTHROPIC_API_KEY` by default. Subscription authentication
  requires explicit Bridge opt-in with `BRIDGE_ALLOW_CLAUDE_OAUTH=1` because
  Anthropic's current official guidance has an unclear scope for this architecture.
  See [Claude authentication troubleshooting](docs/auth-troubleshooting.md).
- CC Pocket is designed around self-hosting and minimal data collection. Supporter purchases
  restore within the same Apple ID or Google account, but do not sync across stores.
  See [Supporter / Purchases](docs/supporter.md).
- Screenshot capture on macOS requires Screen Recording permission for the terminal app
  running the Bridge Server.
- CC Pocket is not affiliated with, endorsed by, or associated with Anthropic or OpenAI.

## Development

```bash
git clone https://github.com/zwthys-cyber/ccpocket.git
cd ccpocket
npm install
cd apps/mobile && flutter pub get && cd ../..
```

Common commands:

| Command | Description |
|---------|-------------|
| `npm run bridge` | Start Bridge Server in dev mode |
| `npm run bridge:build` | Build the Bridge Server |
| `npm run dev` | Restart Bridge and launch the Flutter app |
| `npm run test:bridge` | Run Bridge Server tests |
| `cd apps/mobile && flutter test` | Run Flutter tests |
| `cd apps/mobile && dart analyze` | Run Dart static analysis |

For setup and checks required before submitting a PR, see
[Pre-PR checks](docs/development-testing.md#before-opening-a-pr).
For end-to-end checks with a local Bridge and mobile app, see
[Development Testing](docs/development-testing.md).

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

## License

[MIT](LICENSE)
