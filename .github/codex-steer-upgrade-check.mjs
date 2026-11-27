import assert from 'node:assert/strict';
import { mkdir, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { homedir } from 'node:os';
import { pathToFileURL } from 'node:url';
import { randomUUID } from 'node:crypto';
const dist = join(process.cwd(), 'packages/bridge/dist');
const { codexThreadUserTimes, codexThreadToSessionHistory } = await import(pathToFileURL(join(dist, 'sessions-index.js')));
const { applyCodexCanonicalHistoryBaseline } = await import(pathToFileURL(join(dist, 'websocket/session-history.js')));
const { BridgeWebSocketServer } = await import(pathToFileURL(join(dist, 'websocket.js')));
const threadId = randomUUID();
const dir = join(homedir(), '.codex/sessions/2026/11/27');
const start = '2026-11-27T09:18:41.123Z', receipt = '2026-11-27T09:32:09.859Z';
const second = '2026-11-27T09:33:10.000Z';
await mkdir(dir, { recursive: true });
await writeFile(join(dir, `rollout-${threadId}.jsonl`), [
  { type: 'session_meta', payload: { id: threadId } },
  { type: 'response_item', timestamp: '2026-11-27T09:32:09.853Z', payload: { type: 'message', role: 'user', id: 'model-item', content: [{ type: 'input_text', text: 'confirm' }] } },
  { type: 'event_msg', timestamp: receipt, payload: { type: 'item_completed', turn_id: 'turn', started_at_ms: Date.parse(receipt), item: { type: 'UserMessage', id: 'rpc-one' } } },
].map(entry => JSON.stringify(entry)).join('\n'));
const user = (id, text) => ({ type: 'userMessage', id, content: [{ type: 'text', text }] });
const thread = { turns: [{ id: 'turn', startedAt: Date.parse(start)/1000, items: [
  user('rpc-start','begin'), user('rpc-one','confirm'),
  { type: 'agentMessage', id: 'anchor', text: 'working' },
  { ...user('rpc-two','confirm'), startedAtMs: Date.parse(second) },
] }] };
const canonical = () => codexThreadUserTimes(threadId, thread).then(times => codexThreadToSessionHistory(thread, times));
const history = await canonical();
assert.equal(history.find(m => m.rawItemId === 'rpc-one').timestamp, receipt);
const server = Object.create(BridgeWebSocketServer.prototype);
const session = { id:'fixture', provider:'codex', historyRevision: 3, historyEntries: [
  { seq:1, message: { type:'assistant', messageUuid:'anchor', message:{ id:'anchor',role:'assistant',content:[{type:'text',text:'working'}],model:'' } } },
  { seq:2, message: { type:'user_input',text:'confirm',clientMessageId:'accepted-A',userMessageUuid:'codex:user-turn:17',timestamp:receipt } },
  { seq:3, message: { type:'user_input',text:'confirm',clientMessageId:'accepted-B',userMessageUuid:'codex:user-turn:18',rawItemId:'rpc-two',timestamp:second } },
], codexUserTurnUuidByRawId: new Map([['rpc-one','codex:user-turn:17']]) };
for (let i=0;i<3;i++) {
  const source = await canonical();
  const entries = await Promise.all(source.map(async (item,index)=>({ seq:index+1,message: await server.codexHistoryMessageToServerMessage(session,item) })));
  applyCodexCanonicalHistoryBaseline(server,session,source,entries);
  assert.deepEqual(entries.filter(e=>e.message.type==='user_input').map(({message:m})=>[m.text,m.userMessageUuid,m.clientMessageId,m.timestamp]),[
    ['begin','codex:user-turn:1',undefined,start],
    ['confirm','codex:user-turn:2','accepted-A',receipt],
    ['confirm','codex:user-turn:3','accepted-B',second],
  ]);
}
console.log('Packaged state rebuilt: one later steering bubble at 09:32; an intentional equal-text input at 09:33 survived all three snapshots.');
