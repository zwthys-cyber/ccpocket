# Gallery media and delete compatibility

The gallery list, upload response and new-image notification retain the original `url`. New servers may also supply a relative `thumbnailUrl` for grid views. Full-screen viewing, exports and attachments use the original. Clients use the original when the thumbnail field is absent. The thumbnail endpoint may also serve the original MIME type when the decoder cannot produce a preview. Existing index files work without migration.

The server generates a preview when requested, with one active conversion, bounded pending work and a bounded memory cache. The cache is disposable on restart. Originals stream from disk and never need to fit in a response buffer.

Gallery mutations run in order. A deletion moves the gallery copy into the same filesystem's pending-delete directory, atomically replaces the index, then removes the staged file. On startup the server restores files referenced by the committed index and purges completed deletions. A failed index write leaves the photo available for retry. The source file in the user's project is untouched. Repeating an already completed HTTP delete returns 404. A filesystem failure returns 500.
