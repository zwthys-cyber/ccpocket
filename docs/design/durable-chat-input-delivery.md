# Durable chat input delivery

Submitted chat inputs are saved in the local outbox before the composer clears
its text and attachments. A persistence failure leaves the draft available for
retry. Pending inputs survive transport replacement, explicit disconnects, and
app restarts. ACKs and matching canonical history reconcile delivery state.

## Bridge affinity and compatibility

New Bridges include their persisted `bridgeInstanceId` in `session_list`.
Existing prompt-history identity notifications are also accepted. This is an
optional field in protocol v1; no new client message is required. Older clients
ignore it, and older Bridges remain usable.

An input records its originating identity in local outbox metadata, excluded
from the WebSocket payload. A different URL announcing the same instance ID can
retry the input. A different instance ID cannot. During reconnection the client
retains the known identity per normalized endpoint, so input typed before the
handshake cannot become associated with a subsequently selected Bridge.

If an older Bridge does not announce an identity, the client uses a local
`legacy-endpoint:` scope consisting of scheme, host, effective port, and path.
Retries are restricted to that endpoint. When that endpoint announces a real
identity, its legacy-scoped records can migrate to that identity. Records bound
to a different real identity are never rebound. Legacy endpoint scope cannot
detect server replacement at the same address and does not permit retries via
an alternate address until identity is known.

Older outbox records with no origin metadata are associated with the connected
Bridge after restoration completes. Their original destination cannot be
reconstructed. Binding after restoration also handles storage reads completing
after the handshake.

## Navigation and delivery limits

A selected chat remains visible during disconnection and reconnection to the
same endpoint. An explicit connection to another endpoint first disposes the
old workspace, preventing its history requests or retries from reaching the
new Bridge. A different address is treated conservatively as a switch even if
it ultimately reaches the same server.

This is durable retry, not an exactly-once protocol. If the Bridge accepts input
but its ACK/history is unavailable before retry, the input can be submitted
again. A lost/reset Bridge identity leaves inputs bound to the previous ID
pending. Outbox persistence uses the existing local SharedPreferences storage;
it does not introduce an encrypted store or an OS-level transaction guarantee.
