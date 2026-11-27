import { createServer } from "node:http";
import type { AddressInfo } from "node:net";
import sharp from "sharp";
import { mkdir, mkdtemp, readFile, rm, writeFile, readdir, rename, unlink } from "node:fs/promises";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const { TEST_HOME, indexWrites } = vi.hoisted(() => ({
  TEST_HOME: `/tmp/ccpocket-gallery-test-home-${process.pid}`,
  indexWrites: { failNext: false, inFlight: 0, maxInFlight: 0, targets: [] as string[] },
}));

vi.mock("node:fs/promises", async (importOriginal) => {
  const mod = await importOriginal<typeof import("node:fs/promises")>();
  const writeFile = (async (...args: Parameters<typeof mod.writeFile>) => {
    const target = String(args[0]);
    if (!target.includes(`${TEST_HOME}/.ccpocket/gallery/index.json`)) {
      return mod.writeFile(...args);
    }
    if (indexWrites.failNext) {
      indexWrites.failNext = false;
      throw new Error("simulated index write failure");
    }
    indexWrites.targets.push(target);
    indexWrites.inFlight += 1;
    indexWrites.maxInFlight = Math.max(
      indexWrites.maxInFlight,
      indexWrites.inFlight,
    );
    try {
      // Widen the race window so overlapping writes are observable.
      await new Promise((r) => setTimeout(r, 5));
      return await mod.writeFile(...args);
    } finally {
      indexWrites.inFlight -= 1;
    }
  }) as typeof mod.writeFile;
  return { ...mod, writeFile };
});

vi.mock("node:os", async (importOriginal) => {
  const mod = await importOriginal<typeof import("node:os")>();
  return {
    ...mod,
    homedir: () => TEST_HOME,
  };
});

import { GalleryStore } from "./gallery-store.js";

describe("GalleryStore.addImage", () => {
  beforeEach(async () => {
    await rm(TEST_HOME, { recursive: true, force: true });
    await mkdir(TEST_HOME, { recursive: true });
  });

  afterEach(async () => {
    await rm(TEST_HOME, { recursive: true, force: true });
  });

  it("resolves leading-slash project-relative paths", async () => {
    const root = await mkdtemp(join(tmpdir(), "ccpocket-gallery-project-"));
    try {
      const imageDir = join(root, "images");
      const imagePath = join(imageDir, "screenshots.png");
      await mkdir(imageDir, { recursive: true });
      await writeFile(imagePath, Buffer.from("89504e470d0a1a0a", "hex"));

      const store = new GalleryStore();
      await store.init();

      const meta = await store.addImage("/images/screenshots.png", root, "session-1");
      expect(meta).not.toBeNull();
      expect(meta?.sourcePath).toBe(imagePath);
      expect(meta?.mimeType).toBe("image/png");
    } finally {
      await rm(root, { recursive: true, force: true });
    }
  });
});

describe("GalleryStore index persistence", () => {
  beforeEach(async () => {
    await rm(TEST_HOME, { recursive: true, force: true });
    await mkdir(TEST_HOME, { recursive: true });
    indexWrites.inFlight = 0;
    indexWrites.maxInFlight = 0;
    indexWrites.targets = [];
  });

  afterEach(async () => {
    await rm(TEST_HOME, { recursive: true, force: true });
  });

  it("serializes concurrent index saves and writes atomically", async () => {
    const root = await mkdtemp(join(tmpdir(), "ccpocket-gallery-project-"));
    try {
      const count = 8;
      for (let i = 0; i < count; i++) {
        await writeFile(
          join(root, `shot-${i}.png`),
          Buffer.from("89504e470d0a1a0a", "hex"),
        );
      }

      const store = new GalleryStore();
      await store.init();
      const metas = await Promise.all(
        Array.from({ length: count }, (_, i) =>
          store.addImage(join(root, `shot-${i}.png`), root),
        ),
      );
      expect(metas.every((m) => m !== null)).toBe(true);

      expect(indexWrites.maxInFlight).toBe(1);
      const indexFile = join(TEST_HOME, ".ccpocket", "gallery", "index.json");
      // Never truncate the live index in place; write a temp file and rename.
      expect(indexWrites.targets).not.toContain(indexFile);

      const parsed = JSON.parse(await readFile(indexFile, "utf-8")) as unknown[];
      expect(parsed).toHaveLength(count);

      const reloaded = new GalleryStore();
      await reloaded.init();
      expect(reloaded.list()).toHaveLength(count);
    } finally {
      await rm(root, { recursive: true, force: true });
    }
  });
});

describe("GalleryStore deletion and media", () => {
  const gallery = join(TEST_HOME, ".ccpocket", "gallery");
  let store: GalleryStore;

  beforeEach(async () => {
    await rm(TEST_HOME, { recursive: true, force: true });
    store = new GalleryStore();
    await store.init();
  });
  afterEach(async () => { await rm(TEST_HOME, { recursive: true, force: true }); });

  async function add(body: Buffer) {
    const meta = await store.addImageFromBase64(body.toString("base64"), "image/png", "/project");
    expect(meta).not.toBeNull();
    return meta!;
  }

  it("removes only targeted IDs during overlapping deletes, repeated requests and an addition", async () => {
    const [a, b, survivor] = await Promise.all(["a", "b", "c"].map(s => add(Buffer.from(s))));
    const results = await Promise.all([
      store.delete(a.id), store.delete(b.id), store.delete(a.id), add(Buffer.from("d")),
    ] as const);
    expect(results.slice(0, 3)).toEqual([true, true, false]);
    const reloaded = new GalleryStore();
    await reloaded.init();
    expect(reloaded.list().map(m => m.id).sort()).toEqual([survivor.id, results[3].id].sort());
    expect(await readFile(reloaded.getImagePath(survivor.id)!)).toEqual(Buffer.from("c"));
    expect(await readdir(join(gallery, "pending-delete"))).toEqual([]);
  });

  it("restores the original and keeps the index if a delete cannot be committed", async () => {
    const meta = await add(Buffer.from("original"));
    indexWrites.failNext = true;
    await expect(store.delete(meta.id)).rejects.toThrow("simulated index write failure");
    expect(await readFile(store.getImagePath(meta.id)!)).toEqual(Buffer.from("original"));
    const reloaded = new GalleryStore();
    await reloaded.init();
    expect(reloaded.list().map(m => m.id)).toEqual([meta.id]);
    expect(await reloaded.delete(meta.id)).toBe(true);
  });

  it("recovers both sides of a delete interrupted across the atomic index rename", async () => {
    const meta = await add(Buffer.from("restore me"));
    const staged = join(gallery, "pending-delete");
    await rename(store.getImagePath(meta.id)!, join(staged, meta.id));
    await writeFile(join(staged, "already-committed"), "discard me");
    const reloaded = new GalleryStore();
    await reloaded.init();
    expect(await readFile(reloaded.getImagePath(meta.id)!)).toEqual(Buffer.from("restore me"));
    expect(await readdir(staged)).toEqual([]);
  });

  it("keeps the item on a staging failure and reconciles files already removed", async () => {
    const meta = await add(Buffer.from("still here"));
    const staged = join(gallery, "pending-delete", meta.id);
    await mkdir(staged);
    await expect(store.delete(meta.id)).rejects.toThrow();
    expect(await readFile(store.getImagePath(meta.id)!)).toEqual(Buffer.from("still here"));
    await rm(staged, { recursive: true });
    await unlink(store.getImagePath(meta.id)!);
    expect(await store.delete(meta.id)).toBe(true);
    expect(await store.delete(meta.id)).toBe(false);
  });

  it("serves legacy originals, lazily generated previews and decode fallbacks over HTTP", async () => {
    const original = await sharp({ create: {
      width: 900, height: 900, channels: 4, background: "#568ba8",
    } }).png().toBuffer();
    const [meta, damaged] = await Promise.all([add(original), add(Buffer.from("invalid raster"))]);
    // No thumbnail metadata needs to be added to the index of an existing gallery.
    const restarted = new GalleryStore();
    await restarted.init();
    const info = restarted.list().find(image => image.id === meta.id)!;
    expect(info.thumbnailUrl).toBe(`${info.url}?variant=thumbnail`);
    const server = createServer((req, res) => {
      if (!restarted.handleRequest(req, res)) { res.writeHead(404); res.end(); }
    });
    await new Promise<void>(resolve => server.listen(0, "127.0.0.1", resolve));
    const base = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
    try {
      const raw = await fetch(base + info.url);
      expect(raw.headers.get("Content-Type")).toBe("image/png");
      expect(Buffer.from(await raw.arrayBuffer())).toEqual(original);
      const thumbnails = await Promise.all([1, 2].map(async () => {
        const res = await fetch(base + info.thumbnailUrl);
        expect(res.headers.get("Content-Type")).toBe("image/webp");
        return Buffer.from(await res.arrayBuffer());
      }));
      expect(thumbnails[0]).toEqual(thumbnails[1]);
      expect(await sharp(thumbnails[0]).metadata()).toMatchObject({ width: 448, height: 448 });
      const bad = await fetch(base + restarted.metaToInfo(damaged).thumbnailUrl);
      expect(bad.headers.get("Content-Type")).toBe("image/png");
      expect(await bad.text()).toBe("invalid raster");
      expect((await fetch(base + info.url, { method: "DELETE" })).status).toBe(200);
      expect((await fetch(base + info.url, { method: "DELETE" })).status).toBe(404);
      expect((await fetch(base + info.thumbnailUrl)).status).toBe(404);
    } finally {
      await new Promise<void>((resolve, reject) => server.close(err => err ? reject(err) : resolve()));
    }
  });
});
