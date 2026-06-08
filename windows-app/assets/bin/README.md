# Bundled binaries

Place the following Windows executables here before building/running:

- `yt-dlp.exe` — download engine (https://github.com/yt-dlp/yt-dlp/releases)
- `ffmpeg.exe` — stream merging / audio extraction (https://www.gyan.dev/ffmpeg/builds/)

At runtime the app resolves these from this bundled `assets/bin/` location and
copies them into the app's writable data directory (so the engine self-update
can replace `yt-dlp.exe`). See `lib/core/engine/binary_resolver.dart`.

These binaries are intentionally NOT committed to source control.
