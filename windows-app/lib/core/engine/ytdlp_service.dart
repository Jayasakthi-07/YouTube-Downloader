import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/app_enums.dart';
import '../models/download_options.dart';
import '../models/download_progress.dart';
import '../models/download_task.dart';
import '../models/video_info.dart';
import 'binary_resolver.dart';

/// Thrown when an engine invocation fails in a way worth surfacing.
class EngineException implements Exception {
  EngineException(this.message);
  final String message;
  @override
  String toString() => 'EngineException: $message';
}

/// A running download the caller can pause/cancel. Wraps the yt-dlp [Process].
class DownloadHandle {
  DownloadHandle(this._process, this.exitCode);

  final Process _process;

  /// Completes with the process exit code (0 = success).
  final Future<int> exitCode;

  /// The resolved output file path, captured from stdout during the run.
  String? resolvedFilePath;

  /// Last few stderr lines, for surfacing failure reasons.
  final List<String> errorTail = [];

  /// Terminate the process. The partial `.part` file is preserved by yt-dlp,
  /// so a later run with the same args resumes automatically.
  void terminate() {
    _process.kill(ProcessSignal.sigterm);
  }
}

/// Wraps the bundled `yt-dlp.exe`, providing metadata extraction and
/// controllable downloads with machine-parseable live progress.
class YtDlpService {
  YtDlpService(this._bin);

  final BinaryResolver _bin;

  /// Progress template that emits one parseable line per tick (with --newline).
  static const _progressTemplate =
      'download:TVPROG|%(progress.status)s|%(progress.downloaded_bytes)s|'
      '%(progress.total_bytes,progress.total_bytes_estimate)s|'
      '%(progress.speed)s|%(progress.eta)s';

  void _assertReady() {
    if (!_bin.ytDlpExists) {
      throw EngineException(
        'yt-dlp.exe was not found. Open Settings → Update engine, or place '
        'yt-dlp.exe in the app data bin folder.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Metadata
  // ---------------------------------------------------------------------------

  /// Fetches full metadata for a single video via `--dump-single-json`.
  Future<VideoInfo> fetchMetadata(String url) async {
    _assertReady();
    final result = await Process.run(_bin.ytDlpPath, [
      '--dump-single-json',
      '--no-warnings',
      '--no-playlist',
      url,
    ]);
    if (result.exitCode != 0) {
      throw EngineException(_firstError(result.stderr.toString()));
    }
    final json = jsonDecode(result.stdout.toString()) as Map<String, dynamic>;
    return VideoInfo.fromJson(json);
  }

  /// Fetches a flat playlist listing (titles + ids, no per-video formats).
  Future<VideoInfo> fetchPlaylist(String url) async {
    _assertReady();
    final result = await Process.run(_bin.ytDlpPath, [
      '--dump-single-json',
      '--flat-playlist',
      '--no-warnings',
      url,
    ]);
    if (result.exitCode != 0) {
      throw EngineException(_firstError(result.stderr.toString()));
    }
    final json = jsonDecode(result.stdout.toString()) as Map<String, dynamic>;
    return VideoInfo.fromJson(json);
  }

  // ---------------------------------------------------------------------------
  // Download
  // ---------------------------------------------------------------------------

  /// Builds the full yt-dlp argument list for [task] into [outputDir].
  List<String> buildArgs(DownloadTask task, String outputDir) {
    final o = task.options;
    final outTemplate = '$outputDir${Platform.pathSeparator}'
        '%(title).200B [%(id)s].%(ext)s';

    final args = <String>[
      '--newline',
      '--no-colors',
      '--progress-template', _progressTemplate,
      '--ffmpeg-location', _bin.ffmpegPath,
      '--no-mtime',
      '-o', outTemplate,
    ];

    // Playlist handling.
    if (o.playlistItems != null && o.playlistItems!.isNotEmpty) {
      args..add('--yes-playlist')..addAll(['--playlist-items', o.playlistItems!]);
    } else {
      args.add('--no-playlist');
    }

    // Performance: parallel fragments + optional rate limit.
    if (o.concurrentFragments > 1) {
      args.addAll(['-N', '${o.concurrentFragments}']);
    }
    if (o.rateLimitKbps != null && o.rateLimitKbps! > 0) {
      args.addAll(['--limit-rate', '${o.rateLimitKbps}K']);
    }

    // SponsorBlock segment removal (skips actual downloads/thumbnail/subs).
    if (o.sponsorBlock &&
        o.sponsorCategories.isNotEmpty &&
        (o.type == DownloadType.video || o.type == DownloadType.audio)) {
      args.addAll(['--sponsorblock-remove', o.sponsorCategories.join(',')]);
    }

    // Clip a section of the timeline.
    if (o.hasClip &&
        (o.type == DownloadType.video || o.type == DownloadType.audio)) {
      final start = (o.clipStart?.isNotEmpty ?? false) ? o.clipStart! : '0';
      final end = (o.clipEnd?.isNotEmpty ?? false) ? o.clipEnd! : 'inf';
      args
        ..addAll(['--download-sections', '*$start-$end'])
        ..add('--force-keyframes-at-cuts');
    }

    switch (o.type) {
      case DownloadType.video:
        final reencodeAudio = o.audioBitrate.isFixed;
        args
          ..addAll([
            '-f',
            o.quality.formatSelector(o.container,
                bestAudioAnyCodec: reencodeAudio)
          ])
          ..addAll(['--merge-output-format', o.container.ext]);
        if (reencodeAudio) {
          // Force a constant-bitrate audio track in the merged file by
          // re-encoding only the audio stream during the merge (video is
          // stream-copied). Codec is chosen to match the container.
          final codec = _mergeAudioCodec(o.container);
          args.addAll([
            '--postprocessor-args',
            'Merger:-c:a $codec -b:a ${o.audioBitrate.kbps}k',
          ]);
        }
        if (o.embedThumbnail) args.add('--embed-thumbnail');
        if (o.embedMetadata) args.add('--embed-metadata');
        if (o.embedChapters) args.add('--embed-chapters');
        _applySubtitles(args, o, embedDefault: o.embedSubtitles);
        break;
      case DownloadType.audio:
        final quality = o.audioFormat.supportsBitrate
            ? o.audioBitrate.ytdlpAudioQuality
            : '0';
        args
          ..add('-x')
          ..addAll(['--audio-format', o.audioFormat.codec])
          ..addAll(['--audio-quality', quality])
          ..addAll(['-f', 'bestaudio/best']);
        if (o.embedThumbnail) args.add('--embed-thumbnail');
        if (o.embedMetadata) args.add('--embed-metadata');
        break;
      case DownloadType.thumbnail:
        args..add('--write-thumbnail')..add('--skip-download');
        break;
      case DownloadType.subtitles:
        args.add('--skip-download');
        _applySubtitles(args, o, embedDefault: false, forceWrite: true);
        break;
    }

    args.add(task.url);
    return args;
  }

  /// Audio codec to use when re-encoding the merged audio track, matched to
  /// the output container (WEBM needs Opus; MP4/MKV use AAC).
  String _mergeAudioCodec(VideoContainer container) =>
      container == VideoContainer.webm ? 'libopus' : 'aac';

  void _applySubtitles(
    List<String> args,
    DownloadOptions o, {
    required bool embedDefault,
    bool forceWrite = false,
  }) {
    final wantWrite = o.writeSubtitleFiles || forceWrite;
    final wantEmbed = embedDefault;
    if (!wantWrite && !wantEmbed && !o.autoSubtitles) return;

    if (o.autoSubtitles) args.add('--write-auto-subs');
    if (wantWrite) {
      args..add('--write-subs')..addAll(['--convert-subs', 'srt']);
    }
    if (wantEmbed) args.add('--embed-subs');
    if (o.subtitleLangs.isNotEmpty) {
      args.addAll(['--sub-langs', o.subtitleLangs.join(',')]);
    }
  }

  /// Starts a download for [task]. Emits [DownloadProgress] via [onProgress]
  /// and raw log lines via [onLog]. Returns a [DownloadHandle] for control.
  Future<DownloadHandle> startDownload(
    DownloadTask task,
    String outputDir, {
    void Function(DownloadProgress)? onProgress,
    void Function(String)? onLog,
  }) async {
    _assertReady();
    final args = buildArgs(task, outputDir);
    final process = await Process.start(_bin.ytDlpPath, args,
        runInShell: false);

    final completer = Completer<int>();
    final handle = DownloadHandle(process, completer.future);

    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      onLog?.call(line);
      final prog = DownloadProgress.tryParseLine(line);
      if (prog != null) {
        onProgress?.call(prog);
      } else {
        _captureDestination(line, handle);
      }
    });

    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      onLog?.call(line);
      handle.errorTail.add(line);
      if (handle.errorTail.length > 12) handle.errorTail.removeAt(0);
    });

    process.exitCode.then((code) {
      if (!completer.isCompleted) completer.complete(code);
    });

    return handle;
  }

  /// Captures the final output path from yt-dlp's informational lines.
  void _captureDestination(String line, DownloadHandle handle) {
    const markers = [
      '[download] Destination: ',
      '[ExtractAudio] Destination: ',
      '[Merger] Merging formats into "',
      '[download] ',
    ];
    for (final m in markers) {
      final idx = line.indexOf(m);
      if (idx < 0) continue;
      if (m.endsWith('"')) {
        final rest = line.substring(idx + m.length);
        final end = rest.indexOf('"');
        if (end > 0) handle.resolvedFilePath = rest.substring(0, end);
        return;
      }
      if (m == '[download] ') {
        // "[download] <path> has already been downloaded"
        final rest = line.substring(idx + m.length);
        if (rest.contains('has already been downloaded')) {
          handle.resolvedFilePath =
              rest.replaceAll(' has already been downloaded', '').trim();
        }
        return;
      }
      handle.resolvedFilePath = line.substring(idx + m.length).trim();
      return;
    }
  }

  /// Returns the installed yt-dlp version string, or null on failure.
  Future<String?> version() async {
    if (!_bin.ytDlpExists) return null;
    try {
      final r = await Process.run(_bin.ytDlpPath, ['--version']);
      return r.exitCode == 0 ? r.stdout.toString().trim() : null;
    } catch (e) {
      debugPrint('yt-dlp version check failed: $e');
      return null;
    }
  }

  String _firstError(String stderr) {
    final lines = const LineSplitter()
        .convert(stderr)
        .where((l) => l.trim().isNotEmpty)
        .toList();
    final errLine = lines.firstWhere(
      (l) => l.toUpperCase().contains('ERROR'),
      orElse: () => lines.isEmpty ? 'Unknown engine error' : lines.last,
    );
    return errLine.replaceFirst(RegExp(r'^ERROR:\s*'), '').trim();
  }
}
