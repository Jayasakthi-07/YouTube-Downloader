import 'package:flutter_test/flutter_test.dart';

import 'package:tubevault/core/models/app_enums.dart';
import 'package:tubevault/core/models/download_progress.dart';
import 'package:tubevault/shared/utils/youtube_url.dart';

void main() {
  group('YoutubeUrl', () {
    test('accepts valid YouTube URLs', () {
      expect(
          YoutubeUrl.isValid('https://www.youtube.com/watch?v=abc123'), isTrue);
      expect(YoutubeUrl.isValid('https://youtu.be/abc123'), isTrue);
      expect(YoutubeUrl.isValid('https://music.youtube.com/watch?v=x'), isTrue);
    });

    test('rejects non-YouTube URLs', () {
      expect(YoutubeUrl.isValid('https://example.com/watch?v=abc'), isFalse);
      expect(YoutubeUrl.isValid('not a url'), isFalse);
      expect(YoutubeUrl.isValid('ftp://youtube.com'), isFalse);
    });

    test('detects playlists and extracts ids', () {
      expect(
          YoutubeUrl.isPlaylist('https://www.youtube.com/playlist?list=PL1'),
          isTrue);
      expect(YoutubeUrl.videoId('https://youtu.be/dQw4w9WgXcQ'),
          equals('dQw4w9WgXcQ'));
      expect(YoutubeUrl.videoId('https://www.youtube.com/watch?v=abc'),
          equals('abc'));
    });
  });

  group('VideoQuality.formatSelector', () {
    test('caps height for mp4 and falls back to best', () {
      final sel = VideoQuality.q1080.formatSelector(VideoContainer.mp4);
      expect(sel, contains('height<=1080'));
      expect(sel, contains('bestvideo'));
    });

    test('best quality has no height cap', () {
      final sel = VideoQuality.best.formatSelector(VideoContainer.mkv);
      expect(sel, isNot(contains('height<=')));
    });

    test('mp4 prefers m4a audio for a lossless remux by default', () {
      final sel = VideoQuality.q720.formatSelector(VideoContainer.mp4);
      expect(sel, contains('bestaudio[ext=m4a]'));
    });

    test('re-encode mode picks best audio of any codec (Opus over AAC)', () {
      final sel = VideoQuality.q720
          .formatSelector(VideoContainer.mp4, bestAudioAnyCodec: true);
      expect(sel, isNot(contains('[ext=m4a]')));
      expect(sel, contains('bestaudio'));
    });
  });

  group('AudioBitrate', () {
    test('source means no re-encode', () {
      expect(AudioBitrate.source.isFixed, isFalse);
      expect(AudioBitrate.source.ytdlpAudioQuality, '0');
    });

    test('fixed bitrate maps to a yt-dlp quality string', () {
      expect(AudioBitrate.k320.isFixed, isTrue);
      expect(AudioBitrate.k320.ytdlpAudioQuality, '320K');
      expect(AudioBitrate.k128.ytdlpAudioQuality, '128K');
    });

    test('WAV does not support a target bitrate', () {
      expect(AudioFormat.wav.supportsBitrate, isFalse);
      expect(AudioFormat.mp3.supportsBitrate, isTrue);
    });
  });

  group('DownloadProgress.tryParseLine', () {
    test('parses a TVPROG progress line', () {
      final p = DownloadProgress.tryParseLine(
          'TVPROG|downloading|500|1000|1234.5|10');
      expect(p, isNotNull);
      expect(p!.downloadedBytes, 500);
      expect(p.totalBytes, 1000);
      expect(p.fraction, closeTo(0.5, 0.001));
      expect(p.speedBytesPerSec, closeTo(1234.5, 0.001));
      expect(p.etaSeconds, 10);
    });

    test('returns null for unrelated lines', () {
      expect(DownloadProgress.tryParseLine('[download] 50%'), isNull);
    });

    test('handles NA fields gracefully', () {
      final p = DownloadProgress.tryParseLine('TVPROG|downloading|0|NA|NA|NA');
      expect(p, isNotNull);
      expect(p!.totalBytes, isNull);
      expect(p.fraction, 0);
    });
  });
}
