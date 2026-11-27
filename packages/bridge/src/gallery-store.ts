import { randomUUID } from "node:crypto";
import { readFile, writeFile, mkdir, copyFile, stat, unlink, rename, readdir, open } from "node:fs/promises";
import { join, extname, basename, isAbsolute, resolve } from "node:path";
import { homedir } from "node:os";
import type { IncomingMessage, ServerResponse } from "node:http";
import { pipeline } from "node:stream/promises";
import { GalleryThumbnails } from "./gallery-thumbnails.js";

export interface GalleryImageMeta {
  id: string;
  filename: string;
  mimeType: string;
  projectPath: string;
  sessionId?: string;
  sourcePath: string;
  addedAt: string;
  sizeBytes: number;
}

export interface GalleryImageInfo {
  id: string;
  url: string;
  thumbnailUrl?: string;
  mimeType: string;
  projectPath: string;
  projectName: string;
  sessionId?: string;
  addedAt: string;
  sizeBytes: number;
}

const GALLERY_DIR = join(homedir(), ".ccpocket", "gallery");
const IMAGES_DIR = join(GALLERY_DIR, "images");
const PENDING_DELETE_DIR = join(GALLERY_DIR, "pending-delete");
const INDEX_FILE = join(GALLERY_DIR, "index.json");

const MIME_TYPES: Record<string, string> = {
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".gif": "image/gif",
  ".webp": "image/webp",
};

function projectNameFromPath(projectPath: string): string {
  const parts = projectPath.split("/").filter(Boolean);
  return parts.length > 0 ? parts[parts.length - 1] : projectPath;
}

async function removeIfPresent(path: string): Promise<void> {
  try {
    await unlink(path);
  } catch (err) {
    if ((err as NodeJS.ErrnoException).code !== "ENOENT") throw err;
  }
}

export class GalleryStore {
  private index: GalleryImageMeta[] = [];
  private initialized = false;
  private mutationChain: Promise<void> = Promise.resolve();
  private thumbnails = new GalleryThumbnails();

  private async resolveReadablePath(filePath: string, projectPath: string): Promise<string | null> {
    const candidates: string[] = [];
    if (isAbsolute(filePath)) {
      candidates.push(filePath);
      candidates.push(resolve(projectPath, filePath.replace(/^\/+/, "")));
    } else {
      candidates.push(resolve(projectPath, filePath));
      candidates.push(filePath);
    }

    for (const candidate of candidates) {
      try {
        const st = await stat(candidate);
        if (st.isFile()) return candidate;
      } catch {
        // Try next candidate.
      }
    }
    return null;
  }

  async init(): Promise<void> {
    await mkdir(IMAGES_DIR, { recursive: true });
    await mkdir(PENDING_DELETE_DIR, { recursive: true });
    try {
      const data = await readFile(INDEX_FILE, "utf-8");
      const entries = JSON.parse(data);
      if (!Array.isArray(entries)) throw new Error("Invalid gallery index");
      this.index = entries as GalleryImageMeta[];
    } catch (err) {
      if ((err as NodeJS.ErrnoException).code !== "ENOENT") throw err;
    }
    // A crash before the index rename leaves the original recoverable. A
    // crash after the rename leaves only an unreferenced file to purge.
    for (const id of await readdir(PENDING_DELETE_DIR)) {
      const staged = join(PENDING_DELETE_DIR, id);
      const meta = this.index.find((entry) => entry.id === id);
      if (meta) await rename(staged, join(IMAGES_DIR, meta.filename));
      else await removeIfPresent(staged);
    }
    this.initialized = true;
  }

  private mutate<T>(operation: () => Promise<T>): Promise<T> {
    if (!this.initialized) return Promise.reject(new Error("Gallery index is unavailable"));
    const next = this.mutationChain.then(operation);
    this.mutationChain = next.then(() => {}, () => {});
    return next;
  }

  private async replaceIndex(entries: GalleryImageMeta[]): Promise<void> {
    const temp = `${INDEX_FILE}.${randomUUID()}.tmp`;
    try {
      await writeFile(temp, JSON.stringify(entries, null, 2), "utf-8");
      await rename(temp, INDEX_FILE);
    } catch (err) {
      await removeIfPresent(temp);
      throw err;
    }
    this.index = entries;
  }

  private async recordImage(meta: GalleryImageMeta): Promise<void> {
    try {
      await this.mutate(() => this.replaceIndex([...this.index, meta]));
    } catch (err) {
      await removeIfPresent(join(IMAGES_DIR, meta.filename));
      throw err;
    }
  }

  async addImage(
    filePath: string,
    projectPath: string,
    sessionId?: string,
  ): Promise<GalleryImageMeta | null> {
    try {
      const resolvedPath = await this.resolveReadablePath(filePath, projectPath);
      if (!resolvedPath) return null;
      const st = await stat(resolvedPath);

      const ext = extname(resolvedPath).toLowerCase();
      const mimeType = MIME_TYPES[ext];
      if (!mimeType) return null;

      const id = randomUUID();
      const filename = `${id}${ext}`;
      const destPath = join(IMAGES_DIR, filename);

      await copyFile(resolvedPath, destPath);

      const meta: GalleryImageMeta = {
        id,
        filename,
        mimeType,
        projectPath,
        sessionId,
        sourcePath: resolvedPath,
        addedAt: new Date().toISOString(),
        sizeBytes: st.size,
      };

      await this.recordImage(meta);

      console.log(`[gallery] Added image ${id} from ${basename(resolvedPath)}`);
      return meta;
    } catch (err) {
      console.warn(`[gallery] Failed to add image ${filePath}:`, err);
      return null;
    }
  }

  /**
   * Add an image from base64-encoded data.
   * This allows mobile clients to upload images directly without file paths.
   */
  async addImageFromBase64(
    base64Data: string,
    mimeType: string,
    projectPath: string,
    sessionId?: string,
  ): Promise<GalleryImageMeta | null> {
    try {
      // Validate mime type and get extension
      const ext = Object.entries(MIME_TYPES).find(([, mime]) => mime === mimeType)?.[0];
      if (!ext) {
        console.warn(`[gallery] Unsupported mime type: ${mimeType}`);
        return null;
      }

      const id = randomUUID();
      const filename = `${id}${ext}`;
      const destPath = join(IMAGES_DIR, filename);

      // Decode base64 and write to file
      const buffer = Buffer.from(base64Data, "base64");
      await writeFile(destPath, buffer);

      const meta: GalleryImageMeta = {
        id,
        filename,
        mimeType,
        projectPath,
        sessionId,
        sourcePath: "base64_upload",
        addedAt: new Date().toISOString(),
        sizeBytes: buffer.length,
      };

      await this.recordImage(meta);

      console.log(`[gallery] Added image ${id} from base64 (${Math.round(buffer.length / 1024)}KB)`);
      return meta;
    } catch (err) {
      console.warn(`[gallery] Failed to add image from base64:`, err);
      return null;
    }
  }

  list(options?: { projectPath?: string; sessionId?: string }): GalleryImageInfo[] {
    let items = this.index;
    if (options?.projectPath) {
      items = items.filter((m) => m.projectPath === options.projectPath);
    }
    if (options?.sessionId) {
      items = items.filter((m) => m.sessionId === options.sessionId);
    }
    // Return newest first
    return [...items]
      .sort((a, b) => new Date(b.addedAt).getTime() - new Date(a.addedAt).getTime())
      .map((meta) => this.metaToInfo(meta));
  }

  getImagePath(id: string): string | null {
    const meta = this.index.find((m) => m.id === id);
    if (!meta) return null;
    return join(IMAGES_DIR, meta.filename);
  }

  /**
   * Get image as Base64 for SDK message embedding.
   * Returns null if image not found.
   */
  async getImageAsBase64(id: string): Promise<{ base64: string; mimeType: string } | null> {
    const meta = this.index.find((m) => m.id === id);
    if (!meta) return null;

    const filePath = join(IMAGES_DIR, meta.filename);
    try {
      const buffer = await readFile(filePath);
      return {
        base64: buffer.toString("base64"),
        mimeType: meta.mimeType,
      };
    } catch {
      return null;
    }
  }

  /**
   * Get mime type for an image by ID.
   */
  getMimeType(id: string): string | null {
    const meta = this.index.find((m) => m.id === id);
    return meta?.mimeType ?? null;
  }

  delete(id: string): Promise<boolean> {
    return this.mutate(async () => {
      const meta = this.index.find((entry) => entry.id === id);
      if (!meta) {
        // An earlier request may have committed but failed to purge its staged file.
        if (/^[a-zA-Z0-9_-]+$/.test(id)) await removeIfPresent(join(PENDING_DELETE_DIR, id));
        return false;
      }
      const original = join(IMAGES_DIR, meta.filename);
      const staged = join(PENDING_DELETE_DIR, id);
      try {
        await rename(original, staged);
      } catch (err) {
        if ((err as NodeJS.ErrnoException).code !== "ENOENT") throw err;
        // rename also returns ENOENT when its destination directory vanished.
        // Only a missing original is an already-completed file removal.
        await stat(PENDING_DELETE_DIR);
      }
      try {
        await this.replaceIndex(this.index.filter((entry) => entry.id !== id));
      } catch (err) {
        // Keep a failed delete retryable, including after a process restart.
        try {
          await rename(staged, original);
        } catch (restoreError) {
          if ((restoreError as NodeJS.ErrnoException).code !== "ENOENT") throw restoreError;
        }
        throw err;
      }
      this.thumbnails.forget(id);
      await removeIfPresent(staged);
      return true;
    });
  }

  /**
   * Handle HTTP requests for gallery image serving.
   * Returns true if the request was handled.
   */
  handleRequest(req: IncomingMessage, res: ServerResponse): boolean {
    const url = req.url ?? "";

    // Match /api/gallery/:id (alphanumeric, hyphens, underscores)
    const imageMatch = url.match(/^\/api\/gallery\/([a-zA-Z0-9_-]+)(\?variant=thumbnail)?$/);

    // GET /api/gallery/:id — serve image file
    if (imageMatch && req.method === "GET") {
      const id = imageMatch[1];
      void this.serveImage(id, Boolean(imageMatch[2]), res);
      return true;
    }

    // DELETE /api/gallery/:id
    if (imageMatch && !imageMatch[2] && req.method === "DELETE") {
      const id = imageMatch[1];
      this.delete(id).then((ok) => {
        if (ok) {
          res.writeHead(200, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ deleted: true }));
        } else {
          res.writeHead(404, { "Content-Type": "text/plain" });
          res.end("Not Found");
        }
      }).catch(() => {
        res.writeHead(500, { "Content-Type": "text/plain" });
        res.end("Internal Server Error");
      });
      return true;
    }

    // GET /api/gallery — list images (exact path or with query string)
    if ((url === "/api/gallery" || url.startsWith("/api/gallery?")) && req.method === "GET") {
      const parsedUrl = new URL(url, `http://${req.headers.host ?? "localhost"}`);
      const project = parsedUrl.searchParams.get("project") ?? undefined;
      const images = this.list({ projectPath: project });
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ images }));
      return true;
    }

    return false;
  }

  private async serveImage(id: string, thumbnail: boolean, res: ServerResponse): Promise<void> {
    const meta = this.index.find((m) => m.id === id);
    if (!meta) {
      res.writeHead(404, { "Content-Type": "text/plain" });
      res.end("Not Found");
      return;
    }

    const path = join(IMAGES_DIR, meta.filename);
    const headers = { "Cache-Control": "private, max-age=3600", "X-Content-Type-Options": "nosniff" };
    try {
      if (thumbnail && this.thumbnails.supports(meta)) {
        const buffer = await this.thumbnails.get(meta.id, path);
        if (res.destroyed) return;
        if (buffer) {
          res.writeHead(200, { ...headers, "Content-Type": "image/webp", "Content-Length": buffer.length });
          res.end(buffer);
          return;
        }
      }

      const file = await open(path, "r");
      try {
        const info = await file.stat();
        if (!info.isFile() || res.destroyed) {
          if (!res.destroyed) {
            res.writeHead(404);
            res.end("Not Found");
          }
          return;
        }
        res.writeHead(200, { ...headers, "Content-Type": meta.mimeType, "Content-Length": info.size });
        await pipeline(file.createReadStream(), res);
      } finally {
        await file.close();
      }
    } catch {
      if (res.destroyed) return;
      if (res.headersSent) res.destroy();
      else {
        res.writeHead(404, { "Content-Type": "text/plain" });
        res.end("Not Found");
      }
    }
  }

  /**
   * Handle POST /api/gallery/upload.
   * Accepts JSON body with EITHER:
   *   - { filePath: string, projectPath: string, sessionId?: string } (file path mode)
   *   - { base64: string, mimeType: string, projectPath: string, sessionId?: string } (base64 mode)
   * Returns true if the request was handled.
   */
  handleUploadRequest(
    req: IncomingMessage,
    res: ServerResponse,
    onNewImage?: (meta: GalleryImageMeta) => void,
  ): boolean {
    const url = req.url ?? "";
    if (url !== "/api/gallery/upload" || req.method !== "POST") return false;

    let body = "";
    req.on("data", (chunk: Buffer) => { body += chunk.toString(); });
    req.on("end", async () => {
      try {
        const parsed = JSON.parse(body) as {
          filePath?: string;
          base64?: string;
          mimeType?: string;
          projectPath?: string;
          sessionId?: string;
        };

        if (!parsed.projectPath) {
          res.writeHead(400, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ error: "projectPath is required" }));
          return;
        }

        let meta: GalleryImageMeta | null = null;

        // Base64 mode: save from base64 data
        if (parsed.base64 && parsed.mimeType) {
          meta = await this.addImageFromBase64(
            parsed.base64,
            parsed.mimeType,
            parsed.projectPath,
            parsed.sessionId,
          );
        }
        // File path mode: copy from file path
        else if (parsed.filePath) {
          meta = await this.addImage(
            parsed.filePath,
            parsed.projectPath,
            parsed.sessionId,
          );
        } else {
          res.writeHead(400, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ error: "Either filePath or (base64 + mimeType) is required" }));
          return;
        }

        if (!meta) {
          res.writeHead(400, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ error: "Failed to add image (unsupported format or invalid data)" }));
          return;
        }
        const info = this.metaToInfo(meta);
        if (onNewImage) onNewImage(meta);
        res.writeHead(201, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ image: info }));
      } catch {
        res.writeHead(400, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ error: "Invalid JSON body" }));
      }
    });
    return true;
  }

  /** Convert GalleryImageMeta to GalleryImageInfo for WS broadcast. */
  metaToInfo(meta: GalleryImageMeta): GalleryImageInfo {
    return {
      id: meta.id,
      url: `/api/gallery/${meta.id}`,
      ...(this.thumbnails.supports(meta) && { thumbnailUrl: `/api/gallery/${meta.id}?variant=thumbnail` }),
      mimeType: meta.mimeType,
      projectPath: meta.projectPath,
      projectName: projectNameFromPath(meta.projectPath),
      sessionId: meta.sessionId,
      addedAt: meta.addedAt,
      sizeBytes: meta.sizeBytes,
    };
  }
}
