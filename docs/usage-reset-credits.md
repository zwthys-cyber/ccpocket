# Earned Codex limit resets

The settings usage card displays `rateLimitResetCredits` returned by the
authenticated Codex app-server `account/rateLimits/read` RPC. `availableCount`
is authoritative; absent or capped detail rows must not be used to infer the
count. Missing data is shown as unavailable, rather than zero.

The Bridge sends this optional data as `UsageInfo.resetCredits`. Clients of older
Bridges continue to show ordinary usage and an explanatory unavailable state.
Only available, unexpired detail rows receive redemption buttons. If only a
count is returned, Codex selects the credit. Acquisition/consumption history is
not invented from dates supplied manually.

After explicit user confirmation the client sends `consume_usage_reset` with a
fresh request ID, a persisted idempotency key, and optional opaque credit ID.
The Bridge invokes `account/rateLimitResetCredit/consume` and responds with a
correlated `usage_reset_result`. It never initiates redemption during refresh.
Uncertain attempts retain their key and original credit target across retries,
detail/count-only changes, and app restarts. Only one unresolved attempt is
stored per Bridge endpoint. Confirmed
outcomes clear the key. Buttons wait for a fresh usage snapshot after a known
outcome, and usage is fetched again instead of guessing balances or reset times.

The documented outcomes are `reset`, `alreadyRedeemed`, `nothingToReset`, and
`noCredit`. RPC errors, disconnects, timeouts, and older unsupported messages
produce a retry/update message rather than claiming success.

This feature requires a Codex CLI that implements these account RPCs and a
Bridge built from this fork. The stock npm Bridge does not implement this
fork's new WebSocket request.

Reference: https://learn.chatgpt.com/docs/app-server#8-earned-rate-limit-resets-chatgpt
