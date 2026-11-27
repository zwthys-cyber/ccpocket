import { open } from "node:fs/promises";
import sharp from "sharp";
import type { GalleryImageMeta } from "./gallery-store.js";

const MAX_SOURCE_BYTES = 32 * 1024 * 1024;
const MAX_CACHED_ENTRIES = 32;
const MAX_PENDING = 12;
const MAX_THUMBNAIL_BYTES = 128 * 1024;
const THUMBNAIL_EDGE = 448;

async function rasterFile(path: string): Promise<boolean> {
  const file = await open(path, "r");
  try {
    const { size } = await file.stat();
    if (size > MAX_SOURCE_BYTES) return false;
    const signature = Buffer.alloc(12);
    const { bytesRead } = await file.read(signature, 0, signature.length, 0);
    if (bytesRead < 12) return false;
    return signature.subarray(0, 8).equals(Buffer.from("89504e470d0a1a0a", "hex"))
      || signature.readUIntBE(0, 3) === 0xffd8ff
      || ["GIF87a", "GIF89a"].includes(signature.toString("ascii", 0, 6))
      || (signature.toString("ascii", 0, 4) === "RIFF" && signature.toString("ascii", 8, 12) === "WEBP");
  } finally {
    await file.close();
  }
}

/** One decoder at a time, at most 4 MiB of cached WebP output and no disk backfill. */
export class GalleryThumbnails {
  private cache = new Map<string, Buffer | null>();
  private pending = new Map<string, Promise<Buffer | null>>();
  private tail: Promise<unknown> = Promise.resolve();

  supports(meta: GalleryImageMeta): boolean {
    return meta.sizeBytes > 0 && meta.sizeBytes <= MAX_SOURCE_BYTES
      && ["image/png", "image/jpeg", "image/gif", "image/webp"].includes(meta.mimeType);
  }

  forget(id: string): void {
    this.cache.delete(id);
    this.pending.delete(id);
  }

  async get(id: string, path: string): Promise<Buffer | null> {
    if (this.cache.has(id)) {
      const cached = this.cache.get(id) ?? null;
      this.cache.delete(id);
      this.cache.set(id, cached);
      return cached;
    }
    const pending = this.pending.get(id);
    if (pending) return pending;
    if (this.pending.size >= MAX_PENDING) return null;

    const job = this.tail.then(async () => {
      if (!this.pending.has(id) || !await rasterFile(path)) return null;
      const thumbnail = await sharp(path, { limitInputPixels: 24_000_000, pages: 1 })
        .rotate()
        .resize({ width: THUMBNAIL_EDGE, height: THUMBNAIL_EDGE, fit: "inside", withoutEnlargement: true })
        .webp({ quality: 72, effort: 2 })
        .toBuffer();
      return thumbnail.length <= MAX_THUMBNAIL_BYTES ? thumbnail : null;
    }).catch(() => null);
    this.pending.set(id, job);
    this.tail = job;
    const result = await job;
    if (this.pending.get(id) === job) {
      this.pending.delete(id);
      this.cache.set(id, result);
      if (this.cache.size > MAX_CACHED_ENTRIES) this.cache.delete(this.cache.keys().next().value!);
    }
    return result;
  }
}
