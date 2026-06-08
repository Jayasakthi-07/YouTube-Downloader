import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/engine/ytdlp_service.dart';
import '../../core/models/app_enums.dart';
import '../../core/models/download_options.dart';
import '../../core/models/download_progress.dart';
import '../../core/models/download_task.dart';
import '../../core/settings/settings_controller.dart';
import '../../shared/providers.dart';

/// Manages the download queue: concurrency, lifecycle controls, live progress,
/// and persistence to the history table.
class DownloadQueue extends StateNotifier<List<DownloadTask>> {
  DownloadQueue(this._ref) : super(const []);

  final Ref _ref;
  final _uuid = const Uuid();

  /// Active yt-dlp processes keyed by task id.
  final Map<String, DownloadHandle> _handles = {};

  YtDlpService get _engine => _ref.read(ytDlpServiceProvider);
  int get _maxConcurrent =>
      _ref.read(settingsControllerProvider).maxConcurrent;

  int get _activeCount =>
      state.where((t) => t.status == TaskStatus.downloading).length;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Adds a task to the queue and starts the scheduler.
  Future<DownloadTask> enqueue({
    required String url,
    required String title,
    required DownloadOptions options,
    String? thumbnailUrl,
  }) async {
    final task = DownloadTask(
      id: _uuid.v4(),
      url: url,
      title: title,
      options: options,
      thumbnailUrl: thumbnailUrl,
      status: TaskStatus.queued,
    );
    state = [...state, task];
    await _ref.read(historyRepositoryProvider).upsert(task);
    _pump();
    return task;
  }

  /// Restores interrupted tasks from the DB on startup (auto-resume).
  Future<void> restoreInterrupted() async {
    final tasks = await _ref.read(historyRepositoryProvider).interrupted();
    if (tasks.isEmpty) return;
    // Bring them back as paused so the user (or auto-resume) can continue.
    for (final t in tasks) {
      t.status = TaskStatus.paused;
    }
    state = [...tasks, ...state];
  }

  /// Resume all paused tasks (used by auto-resume on network recovery).
  void resumeAll() {
    for (final t in state.where((t) => t.status == TaskStatus.paused)) {
      _setStatus(t.id, TaskStatus.queued);
    }
    _pump();
  }

  void pause(String id) {
    _handles[id]?.terminate();
    _handles.remove(id);
    _setStatus(id, TaskStatus.paused);
    _pump();
  }

  void resume(String id) {
    _setStatus(id, TaskStatus.queued);
    _pump();
  }

  Future<void> cancel(String id) async {
    _handles[id]?.terminate();
    _handles.remove(id);
    _setStatus(id, TaskStatus.canceled);
    await _cleanupPartials(id);
    _pump();
  }

  void retry(String id) {
    final t = _byId(id);
    if (t == null) return;
    _patch(id, (x) => x.copyWith(
          status: TaskStatus.queued,
          error: '',
          progress: DownloadProgress.empty,
        ));
    _pump();
  }

  Future<void> remove(String id) async {
    _handles[id]?.terminate();
    _handles.remove(id);
    state = state.where((t) => t.id != id).toList();
    await _ref.read(historyRepositoryProvider).delete(id);
  }

  void clearFinished() {
    state = state.where((t) => !t.status.isTerminal).toList();
  }

  /// Reorder queued tasks (drag-and-drop). [newIndex] is already adjusted by
  /// [ReorderableListView.onReorderItem] for the removal at [oldIndex].
  void reorder(int oldIndex, int newIndex) {
    final list = [...state];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
  }

  // ---------------------------------------------------------------------------
  // Scheduler
  // ---------------------------------------------------------------------------

  void _pump() {
    if (_activeCount >= _maxConcurrent) return;
    final next = state.firstWhere(
      (t) => t.status == TaskStatus.queued,
      orElse: () => _sentinel,
    );
    if (identical(next, _sentinel)) return;
    _start(next);
    // Fill remaining slots.
    if (_activeCount < _maxConcurrent) _pump();
  }

  Future<void> _start(DownloadTask task) async {
    _setStatus(task.id, TaskStatus.downloading);
    final outDir = await _resolveOutputDir();
    _patch(task.id, (t) => t.copyWith(outputDir: outDir));

    try {
      final handle = await _engine.startDownload(
        task,
        outDir,
        onProgress: (prog) => _patch(task.id, (t) => t.copyWith(progress: prog)),
      );
      _handles[task.id] = handle;

      final code = await handle.exitCode;
      _handles.remove(task.id);

      // If the user paused/canceled mid-flight the status already changed.
      final current = _byId(task.id);
      if (current == null) return;
      if (current.status == TaskStatus.paused ||
          current.status == TaskStatus.canceled) {
        return;
      }

      if (code == 0) {
        await _onCompleted(task.id, handle.resolvedFilePath);
      } else {
        await _onFailed(task.id, handle.errorTail.join('\n'));
      }
    } catch (e) {
      await _onFailed(task.id, e.toString());
    } finally {
      _pump();
    }
  }

  Future<void> _onCompleted(String id, String? filePath) async {
    int? size;
    if (filePath != null && File(filePath).existsSync()) {
      size = await File(filePath).length();
    }
    _patch(
        id,
        (t) => t.copyWith(
              status: TaskStatus.completed,
              filePath: filePath,
              fileSizeBytes: size,
              completedAt: DateTime.now(),
              progress: const DownloadProgress(fraction: 1),
            ));
    final t = _byId(id);
    await _ref.read(historyRepositoryProvider).updateStatus(
          id,
          TaskStatus.completed,
          filePath: filePath,
          size: size,
        );
    if (t != null) {
      await _ref.read(notificationServiceProvider).downloadComplete(t.title);
    }
  }

  Future<void> _onFailed(String id, String error) async {
    _patch(id, (t) => t.copyWith(status: TaskStatus.failed, error: error));
    final t = _byId(id);
    await _ref
        .read(historyRepositoryProvider)
        .updateStatus(id, TaskStatus.failed, error: error);
    if (t != null) {
      await _ref.read(notificationServiceProvider).downloadFailed(t.title);
    }
  }

  Future<String> _resolveOutputDir() async {
    final settings = _ref.read(settingsControllerProvider);
    final dir = settings.downloadDir ?? Directory.systemTemp.path;
    final d = Directory(dir);
    if (!await d.exists()) await d.create(recursive: true);
    return dir;
  }

  Future<void> _cleanupPartials(String id) async {
    final t = _byId(id);
    final dir = t?.outputDir;
    if (dir == null) return;
    try {
      final d = Directory(dir);
      if (!await d.exists()) return;
      await for (final entry in d.list()) {
        if (entry is File &&
            (entry.path.endsWith('.part') || entry.path.endsWith('.ytdl'))) {
          await entry.delete().catchError((_) => entry);
        }
      }
    } catch (e) {
      debugPrint('cleanupPartials failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // State helpers
  // ---------------------------------------------------------------------------

  static final DownloadTask _sentinel = DownloadTask(
    id: '__sentinel__',
    url: '',
    title: '',
    options: const DownloadOptions(),
  );

  DownloadTask? _byId(String id) {
    for (final t in state) {
      if (t.id == id) return t;
    }
    return null;
  }

  void _setStatus(String id, TaskStatus status) =>
      _patch(id, (t) => t.copyWith(status: status));

  void _patch(String id, DownloadTask Function(DownloadTask) f) {
    state = [
      for (final t in state)
        if (t.id == id) f(t) else t,
    ];
  }
}

final downloadQueueProvider =
    StateNotifierProvider<DownloadQueue, List<DownloadTask>>(
  (ref) => DownloadQueue(ref),
);

/// Convenience selectors.
final activeDownloadsProvider = Provider<List<DownloadTask>>((ref) {
  final all = ref.watch(downloadQueueProvider);
  return all
      .where((t) => t.status == TaskStatus.downloading ||
          t.status == TaskStatus.queued ||
          t.status == TaskStatus.paused)
      .toList();
});
