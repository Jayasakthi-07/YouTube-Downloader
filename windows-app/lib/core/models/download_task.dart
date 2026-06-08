import 'app_enums.dart';
import 'download_options.dart';
import 'download_progress.dart';

/// A unit of work in the download queue. Mutable progress is held separately
/// in the controller's reactive state; this object is the persisted record.
class DownloadTask {
  DownloadTask({
    required this.id,
    required this.url,
    required this.title,
    required this.options,
    this.status = TaskStatus.queued,
    this.outputDir,
    this.filePath,
    this.thumbnailUrl,
    this.fileSizeBytes,
    this.error,
    DateTime? createdAt,
    this.completedAt,
    this.progress = DownloadProgress.empty,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String url;
  String title;
  DownloadOptions options;
  TaskStatus status;
  String? outputDir;
  String? filePath;
  String? thumbnailUrl;
  int? fileSizeBytes;
  String? error;
  final DateTime createdAt;
  DateTime? completedAt;

  /// Transient live progress (not persisted between sessions).
  DownloadProgress progress;

  DownloadTask copyWith({
    String? title,
    DownloadOptions? options,
    TaskStatus? status,
    String? outputDir,
    String? filePath,
    String? thumbnailUrl,
    int? fileSizeBytes,
    String? error,
    DateTime? completedAt,
    DownloadProgress? progress,
  }) {
    return DownloadTask(
      id: id,
      url: url,
      title: title ?? this.title,
      options: options ?? this.options,
      status: status ?? this.status,
      outputDir: outputDir ?? this.outputDir,
      filePath: filePath ?? this.filePath,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      error: error ?? this.error,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      progress: progress ?? this.progress,
    );
  }

  Map<String, Object?> toDbMap() => {
        'id': id,
        'url': url,
        'title': title,
        'type': options.type.name,
        'summary': options.summary,
        'status': status.name,
        'output_dir': outputDir,
        'file_path': filePath,
        'thumbnail_url': thumbnailUrl,
        'file_size': fileSizeBytes,
        'error': error,
        'created_at': createdAt.millisecondsSinceEpoch,
        'completed_at': completedAt?.millisecondsSinceEpoch,
      };
}
