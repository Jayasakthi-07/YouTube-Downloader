import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_shell.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/models/app_enums.dart';
import '../../core/models/media_format.dart';
import '../../core/models/video_info.dart';
import '../../main.dart' show initialUrlProvider;
import '../../shared/utils/formatters.dart';
import '../../shared/utils/youtube_url.dart';
import '../../shared/widgets/common.dart';
import 'download_queue.dart';
import 'metadata_controller.dart';
import 'options_controller.dart';
import 'presets.dart';

final clipboardUrlProvider = FutureProvider.autoDispose<String?>((ref) async {
  final data = await Clipboard.getData(Clipboard.kTextPlain);
  final text = data?.text?.trim();
  if (text != null && YoutubeUrl.isValid(text)) return text;
  return null;
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = ref.read(initialUrlProvider);
    if (initial != null) {
      _controller.text = initial;
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fetch() {
    FocusScope.of(context).unfocus();
    ref.read(metadataControllerProvider.notifier).fetch(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(metadataControllerProvider);
    final t = Theme.of(context).textTheme;

    return ListView(
      padding: Spacing.pagePadding,
      children: [
        Entrance(
          child: Text('Download', style: t.headlineLarge),
        ),
        const SizedBox(height: 4),
        Entrance(
          delay: const Duration(milliseconds: 60),
          child: Text(
            'Paste a YouTube link — video, playlist, or search — and craft the perfect download.',
            style: t.bodyLarge
                ?.copyWith(color: context.scheme.onSurface.withValues(alpha: 0.6)),
          ),
        ),
        const SizedBox(height: Spacing.lg),
        Entrance(
          delay: const Duration(milliseconds: 120),
          child: _UrlBar(controller: _controller, onFetch: _fetch),
        ),
        const SizedBox(height: Spacing.md),
        meta.when(
          data: (info) => info == null
              ? const _Welcome()
              : _PreviewAndOptions(info: info, sourceUrl: _controller.text),
          loading: () => const _PreviewSkeleton(),
          error: (e, _) => _ErrorCard(message: '$e', onRetry: _fetch),
        ),
      ],
    );
  }
}

class _UrlBar extends ConsumerWidget {
  const _UrlBar({required this.controller, required this.onFetch});
  final TextEditingController controller;
  final VoidCallback onFetch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clip = ref.watch(clipboardUrlProvider).asData?.value;
    final showChip = clip != null && clip != controller.text;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onSubmitted: (_) => onFetch(),
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'https://www.youtube.com/watch?v=…',
                    prefixIcon: Icon(Icons.link_rounded, color: context.accent),
                    suffixIcon: IconButton(
                      tooltip: 'Paste',
                      icon: const Icon(Icons.content_paste_rounded, size: 18),
                      onPressed: () async {
                        final data =
                            await Clipboard.getData(Clipboard.kTextPlain);
                        if (data?.text != null) controller.text = data!.text!;
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              GradientButton(
                  label: 'Fetch', icon: Icons.search_rounded, onPressed: onFetch),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              if (showChip)
                Padding(
                  padding: const EdgeInsets.only(right: Spacing.sm),
                  child: HoverLift(
                    onTap: () {
                      controller.text = clip;
                      onFetch();
                    },
                    child: PillTag(
                        label: 'Paste detected link',
                        icon: Icons.auto_awesome_rounded),
                  ),
                ),
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final p in DownloadPreset.all)
                        Padding(
                          padding: const EdgeInsets.only(right: Spacing.xs),
                          child: _MiniPreset(preset: p),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniPreset extends ConsumerWidget {
  const _MiniPreset({required this.preset});
  final DownloadPreset preset;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HoverLift(
      onTap: () => ref
          .read(optionsControllerProvider.notifier)
          .applyPreset(preset.build),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.scheme.onSurface.withValues(alpha: 0.04),
          borderRadius: Radii.pillRadius,
          border:
              Border.all(color: context.scheme.onSurface.withValues(alpha: 0.08)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(preset.icon, size: 15, color: context.accent),
          const SizedBox(width: 6),
          Text(preset.label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: Spacing.xxl),
      child: EmptyState(
        icon: Icons.video_library_outlined,
        title: 'Ready when you are',
        message:
            'Paste a YouTube link above and press Fetch to see a live preview '
            'and tailor your download.',
      ),
    );
  }
}

class _PreviewAndOptions extends ConsumerWidget {
  const _PreviewAndOptions({required this.info, required this.sourceUrl});
  final VideoInfo info;
  final String sourceUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (info.isPlaylist) {
      return Entrance(
        child: GlassCard(
          child: Row(children: [
            Icon(Icons.playlist_play_rounded, color: context.accent, size: 30),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                'This is a playlist with ${info.playlistEntries.length} videos. '
                'Open Playlists to select and batch-download.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            GradientButton(
              label: 'Open Playlists',
              onPressed: () => ref.read(navIndexProvider.notifier).state = 4,
            ),
          ]),
        ),
      );
    }
    return Column(
      children: [
        Entrance(child: _PreviewCard(info: info)),
        const SizedBox(height: Spacing.md),
        Entrance(
          delay: const Duration(milliseconds: 80),
          child: _OptionsPanel(info: info, sourceUrl: sourceUrl),
        ),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.info});
  final VideoInfo info;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radii.sm),
            child: Stack(
              children: [
                SizedBox(
                  width: 280,
                  height: 158,
                  child: info.thumbnailUrl == null
                      ? ColoredBox(
                          color: context.scheme.onSurface
                              .withValues(alpha: 0.05))
                      : CachedNetworkImage(
                          imageUrl: info.thumbnailUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) =>
                              const SkeletonBox(height: 158, radius: 14),
                          errorWidget: (_, _, _) =>
                              const Icon(Icons.broken_image_outlined),
                        ),
                ),
                if (info.duration != null)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: Radii.pillRadius,
                      ),
                      child: Text(Fmt.duration(info.duration),
                          style: AppTheme.mono(context,
                              size: 11, color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleLarge),
                const SizedBox(height: Spacing.xs),
                Row(children: [
                  Icon(Icons.account_circle_outlined,
                      size: 16,
                      color: context.scheme.onSurface.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Flexible(
                      child: Text(info.channelName,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodyMedium)),
                ]),
                const SizedBox(height: Spacing.sm),
                Wrap(spacing: Spacing.xs, runSpacing: Spacing.xs, children: [
                  if (info.availableHeights.isNotEmpty)
                    PillTag(
                        label: 'up to ${info.availableHeights.first}p',
                        icon: Icons.hd_rounded),
                  if (info.viewCount != null)
                    PillTag(
                        label: '${Fmt.compact(info.viewCount)} views',
                        icon: Icons.visibility_outlined,
                        color: context.scheme.onSurface.withValues(alpha: 0.6),
                        filled: false),
                  if (info.subtitleLangs.isNotEmpty)
                    PillTag(
                        label: '${info.subtitleLangs.length} caption tracks',
                        icon: Icons.closed_caption_outlined,
                        filled: false),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionsPanel extends ConsumerWidget {
  const _OptionsPanel({required this.info, required this.sourceUrl});
  final VideoInfo info;
  final String sourceUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opts = ref.watch(optionsControllerProvider);
    final ctl = ref.read(optionsControllerProvider.notifier);
    final maxHeight =
        info.availableHeights.isEmpty ? 0 : info.availableHeights.first;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('Download options', icon: Icons.tune_rounded),
          _ModeSelector(type: opts.type, onChanged: ctl.setType),
          const SizedBox(height: Spacing.md),
          if (opts.type == DownloadType.video) ...[
            _ChipGroup(
              label: 'Quality',
              child: Wrap(spacing: Spacing.xs, runSpacing: Spacing.xs, children: [
                for (final q in VideoQuality.values.where((q) =>
                    q == VideoQuality.best ||
                    maxHeight == 0 ||
                    q.maxHeight <= maxHeight))
                  _Choice(
                      label: q.label,
                      selected: opts.quality == q,
                      onTap: () => ctl.setQuality(q)),
              ]),
            ),
            const SizedBox(height: Spacing.md),
            _ChipGroup(
              label: 'Container',
              child: Wrap(spacing: Spacing.xs, children: [
                for (final c in VideoContainer.values)
                  _Choice(
                      label: c.label,
                      selected: opts.container == c,
                      onTap: () => ctl.setContainer(c)),
              ]),
            ),
            const SizedBox(height: Spacing.md),
            _BitrateGroup(videoMode: true),
            const SizedBox(height: Spacing.md),
            _FileInfo(info: info),
          ] else if (opts.type == DownloadType.audio) ...[
            _ChipGroup(
              label: 'Audio format',
              child: Wrap(spacing: Spacing.xs, children: [
                for (final a in AudioFormat.values)
                  _Choice(
                      label: a.label,
                      selected: opts.audioFormat == a,
                      onTap: () => ctl.setAudioFormat(a)),
              ]),
            ),
            if (opts.audioFormat.supportsBitrate) ...[
              const SizedBox(height: Spacing.md),
              _BitrateGroup(),
            ],
          ] else if (opts.type == DownloadType.subtitles) ...[
            _SubtitleOptions(info: info),
          ] else
            Text('The maximum-resolution thumbnail will be saved as an image.',
                style: Theme.of(context).textTheme.bodyMedium),

          const SizedBox(height: Spacing.md),
          _AdvancedPanel(info: info),

          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              Expanded(
                child: Text('Output · ${opts.summary}',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
              const SizedBox(width: Spacing.sm),
              GradientButton(
                label: 'Add to queue',
                icon: Icons.download_rounded,
                onPressed: () async {
                  await ref.read(downloadQueueProvider.notifier).enqueue(
                        url: sourceUrl,
                        title: info.title,
                        options: opts,
                        thumbnailUrl: info.thumbnailUrl,
                      );
                  if (context.mounted) {
                    showToast(context, 'Added to queue: ${info.title}');
                    ref.read(navIndexProvider.notifier).state = 2;
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.type, required this.onChanged});
  final DownloadType type;
  final ValueChanged<DownloadType> onChanged;

  static const _modes = [
    (DownloadType.video, Icons.movie_outlined, 'Video'),
    (DownloadType.audio, Icons.music_note_outlined, 'Audio'),
    (DownloadType.thumbnail, Icons.image_outlined, 'Thumbnail'),
    (DownloadType.subtitles, Icons.closed_caption_outlined, 'Subtitles'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.scheme.onSurface.withValues(alpha: 0.04),
        borderRadius: Radii.fieldRadius,
        border:
            Border.all(color: context.scheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          for (final (mode, icon, label) in _modes)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(mode),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: Motion.fast,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radii.xs),
                      gradient: type == mode
                          ? LinearGradient(colors: context.accentGradient)
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon,
                            size: 17,
                            color: type == mode
                                ? Colors.white
                                : context.scheme.onSurface
                                    .withValues(alpha: 0.7)),
                        const SizedBox(width: 6),
                        Text(label,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: type == mode
                                    ? Colors.white
                                    : context.scheme.onSurface
                                        .withValues(alpha: 0.7))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BitrateGroup extends ConsumerWidget {
  const _BitrateGroup({this.videoMode = false});
  final bool videoMode;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected =
        ref.watch(optionsControllerProvider.select((o) => o.audioBitrate));
    final ctl = ref.read(optionsControllerProvider.notifier);
    return _ChipGroup(
      label: videoMode ? 'Audio bitrate' : 'Audio quality',
      hint: selected.isFixed && videoMode
          ? 'Re-encodes merged audio to a constant ${selected.label}. '
              'YouTube source audio is ~128–160 kbps.'
          : null,
      child: Wrap(spacing: Spacing.xs, children: [
        for (final b in AudioBitrate.values)
          _Choice(
              label: b.label,
              selected: selected == b,
              onTap: () => ctl.setAudioBitrate(b)),
      ]),
    );
  }
}

class _SubtitleOptions extends ConsumerWidget {
  const _SubtitleOptions({required this.info});
  final VideoInfo info;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opts = ref.watch(optionsControllerProvider);
    final ctl = ref.read(optionsControllerProvider.notifier);
    final langs = {...info.subtitleLangs, ...info.autoSubtitleLangs}.toList()
      ..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: Spacing.md, runSpacing: 0, children: [
          _SwitchRow(
              label: 'Write .srt file',
              value: opts.writeSubtitleFiles,
              onChanged: ctl.toggleWriteSubtitles),
          _SwitchRow(
              label: 'Embed in video',
              value: opts.embedSubtitles,
              onChanged: ctl.toggleEmbedSubtitles),
          _SwitchRow(
              label: 'Auto-generated',
              value: opts.autoSubtitles,
              onChanged: ctl.toggleAutoSubtitles),
        ]),
        if (langs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.xs),
            child: Wrap(spacing: Spacing.xs, runSpacing: Spacing.xs, children: [
              for (final lang in langs.take(14))
                _Choice(
                    label: lang,
                    selected: opts.subtitleLangs.contains(lang),
                    onTap: () {
                      final next = [...opts.subtitleLangs];
                      next.contains(lang) ? next.remove(lang) : next.add(lang);
                      ctl.setSubtitleLangs(next);
                    }),
            ]),
          ),
      ],
    );
  }
}

class _AdvancedPanel extends ConsumerStatefulWidget {
  const _AdvancedPanel({required this.info});
  final VideoInfo info;
  @override
  ConsumerState<_AdvancedPanel> createState() => _AdvancedPanelState();
}

class _AdvancedPanelState extends ConsumerState<_AdvancedPanel> {
  bool _open = false;
  final _startCtl = TextEditingController();
  final _endCtl = TextEditingController();

  @override
  void dispose() {
    _startCtl.dispose();
    _endCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opts = ref.watch(optionsControllerProvider);
    final ctl = ref.read(optionsControllerProvider.notifier);
    final t = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: context.scheme.onSurface.withValues(alpha: 0.03),
        borderRadius: Radii.fieldRadius,
        border:
            Border.all(color: context.scheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          HoverLift(
            onTap: () => setState(() => _open = !_open),
            scale: 1,
            lift: 0,
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(children: [
                Icon(Icons.science_outlined, size: 18, color: context.accent),
                const SizedBox(width: Spacing.xs),
                Text('Advanced', style: t.titleMedium),
                const SizedBox(width: Spacing.xs),
                if (opts.sponsorBlock || opts.hasClip)
                  PillTag(
                      label: [
                        if (opts.sponsorBlock) 'SponsorBlock',
                        if (opts.hasClip) 'Clip'
                      ].join(' · '),
                      filled: true),
                const Spacer(),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: Motion.fast,
                  child: const Icon(Icons.expand_more_rounded),
                ),
              ]),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.md, 0, Spacing.md, Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: Spacing.xs),
                  _SwitchRow(
                      label: 'Remove sponsor segments (SponsorBlock)',
                      value: opts.sponsorBlock,
                      onChanged: ctl.toggleSponsorBlock),
                  _SwitchRow(
                      label: 'Embed metadata',
                      value: opts.embedMetadata,
                      onChanged: ctl.toggleEmbedMetadata),
                  _SwitchRow(
                      label: 'Embed chapters',
                      value: opts.embedChapters,
                      onChanged: ctl.toggleEmbedChapters),
                  const SizedBox(height: Spacing.sm),
                  Text('Clip section (optional)', style: t.labelLarge),
                  const SizedBox(height: Spacing.xs),
                  Row(children: [
                    Expanded(child: _TimeField(controller: _startCtl, hint: 'Start  0:30')),
                    const SizedBox(width: Spacing.sm),
                    Expanded(child: _TimeField(controller: _endCtl, hint: 'End  2:15')),
                    const SizedBox(width: Spacing.sm),
                    OutlinedButton(
                      onPressed: () =>
                          ctl.setClip(_startCtl.text, _endCtl.text),
                      child: const Text('Apply'),
                    ),
                  ]),
                  const SizedBox(height: Spacing.md),
                  Row(children: [
                    Expanded(
                      child: _DropdownRow<int>(
                        label: 'Speed limit',
                        value: opts.rateLimitKbps ?? 0,
                        items: const {
                          0: 'Unlimited',
                          1024: '1 MB/s',
                          2048: '2 MB/s',
                          5120: '5 MB/s',
                          10240: '10 MB/s',
                        },
                        onChanged: (v) => ctl.setRateLimit(v == 0 ? null : v),
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: _DropdownRow<int>(
                        label: 'Parallel fragments',
                        value: opts.concurrentFragments,
                        items: {for (var n in [1, 2, 4, 8, 16]) n: '$n×'},
                        onChanged: ctl.setConcurrentFragments,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            crossFadeState:
                _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: Motion.normal,
          ),
        ],
      ),
    );
  }
}

class _FileInfo extends ConsumerWidget {
  const _FileInfo({required this.info});
  final VideoInfo info;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxH = ref.watch(optionsControllerProvider.select((o) => o.quality.maxHeight));
    final f = _matchFormat(info, maxH);
    if (f == null) return const SizedBox.shrink();
    final pairs = <(String, String)>[
      ('Resolution', f.resolution),
      ('FPS', f.fps?.toStringAsFixed(0) ?? '—'),
      ('Bitrate', Fmt.bitrate(f.tbr)),
      ('Video', f.vcodec ?? '—'),
      ('Audio', f.acodec ?? '—'),
      ('Est. size', Fmt.bytes(f.effectiveSize)),
    ];
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: context.scheme.onSurface.withValues(alpha: 0.03),
        borderRadius: Radii.fieldRadius,
      ),
      child: Wrap(
        spacing: Spacing.xl,
        runSpacing: Spacing.sm,
        children: [
          for (final (k, v) in pairs)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(k,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.scheme.onSurface
                            .withValues(alpha: 0.5))),
                const SizedBox(height: 2),
                Text(v,
                    style: AppTheme.mono(context, size: 13)
                        .copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
        ],
      ),
    );
  }

  static MediaFormat? _matchFormat(VideoInfo info, int maxHeight) {
    final vids = info.formats.where((f) => f.hasVideo && f.height != null);
    if (vids.isEmpty) return info.formats.isEmpty ? null : info.formats.last;
    final eligible =
        maxHeight == 0 ? vids : vids.where((f) => f.height! <= maxHeight);
    final pool = eligible.isEmpty ? vids : eligible;
    return pool.reduce((a, b) => (a.height ?? 0) >= (b.height ?? 0) ? a : b);
  }
}

// --- shared bits ------------------------------------------------------------

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({required this.label, required this.child, this.hint});
  final String label;
  final Widget child;
  final String? hint;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: Spacing.xs),
        child,
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(hint!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        context.scheme.onSurface.withValues(alpha: 0.5))),
          ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.fast,
          padding:
              const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? context.accent.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: Radii.pillRadius,
            border: Border.all(
                color: selected
                    ? context.accent.withValues(alpha: 0.6)
                    : context.scheme.onSurface.withValues(alpha: 0.14)),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? context.accent
                      : context.scheme.onSurface.withValues(alpha: 0.8))),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow(
      {required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Switch(value: value, onChanged: onChanged),
        const SizedBox(width: Spacing.xs),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ]),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({required this.controller, required this.hint});
  final TextEditingController controller;
  final String hint;
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppTheme.mono(context, size: 14),
      decoration: InputDecoration(hintText: hint, isDense: true),
    );
  }
}

class _DropdownRow<T> extends StatelessWidget {
  const _DropdownRow(
      {required this.label,
      required this.value,
      required this.items,
      required this.onChanged});
  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: Spacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
          decoration: BoxDecoration(
            color: context.scheme.onSurface.withValues(alpha: 0.04),
            borderRadius: Radii.fieldRadius,
            border: Border.all(
                color: context.scheme.onSurface.withValues(alpha: 0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              isDense: true,
              borderRadius: Radii.cardRadius,
              items: [
                for (final e in items.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => v == null ? null : onChanged(v),
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewSkeleton extends StatelessWidget {
  const _PreviewSkeleton();
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        SkeletonBox(width: 280, height: 158, radius: 14),
        SizedBox(width: Spacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SkeletonBox(height: 22),
            SizedBox(height: Spacing.sm),
            SkeletonBox(height: 14, width: 180),
            SizedBox(height: Spacing.sm),
            SkeletonBox(height: 14, width: 120),
          ]),
        ),
      ]),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glow: Palette.danger,
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: Palette.danger),
        const SizedBox(width: Spacing.sm),
        Expanded(child: Text(message)),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ]),
    );
  }
}
