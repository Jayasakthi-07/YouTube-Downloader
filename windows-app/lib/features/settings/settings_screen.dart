import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/tokens.dart';
import '../../core/models/app_enums.dart';
import '../../core/settings/settings_controller.dart';
import '../../shared/providers.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/utils/storage.dart';
import '../../shared/widgets/common.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsControllerProvider);
    final ctl = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: Spacing.pagePadding,
        children: [
          Text('Settings',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: Spacing.lg),

          // Appearance
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader('Appearance',
                    icon: Icons.palette_outlined),
                _Row(
                  'Theme',
                  trailing: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_outlined)),
                      ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_outlined)),
                      ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto_outlined)),
                    ],
                    selected: {s.themeMode},
                    onSelectionChanged: (v) => ctl.setThemeMode(v.first),
                  ),
                ),
                _Row(
                  'Language',
                  trailing: DropdownButton<String>(
                    value: s.languageCode,
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'es', child: Text('Español')),
                      DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
                      DropdownMenuItem(value: 'fr', child: Text('Français')),
                    ],
                    onChanged: (v) => v == null ? null : ctl.setLanguage(v),
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text('Accent', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: Spacing.sm),
                Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.sm,
                  children: [
                    for (final a in Accents.presets)
                      _AccentSwatch(
                        color: Color(a.argb),
                        selected: s.accentColor == a.argb,
                        onTap: () => ctl.setAccentColor(a.argb),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),

          // Defaults
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader('Download defaults',
                    icon: Icons.tune_rounded),
                _Row(
                  'Default quality',
                  trailing: DropdownButton<VideoQuality>(
                    value: s.defaultQuality,
                    items: [
                      for (final q in VideoQuality.values)
                        DropdownMenuItem(value: q, child: Text(q.label)),
                    ],
                    onChanged: (v) =>
                        v == null ? null : ctl.setDefaultQuality(v),
                  ),
                ),
                _Row(
                  'Default container',
                  trailing: DropdownButton<VideoContainer>(
                    value: s.defaultContainer,
                    items: [
                      for (final c in VideoContainer.values)
                        DropdownMenuItem(value: c, child: Text(c.label)),
                    ],
                    onChanged: (v) =>
                        v == null ? null : ctl.setDefaultContainer(v),
                  ),
                ),
                _Row(
                  'Default audio format',
                  trailing: DropdownButton<AudioFormat>(
                    value: s.defaultAudioFormat,
                    items: [
                      for (final a in AudioFormat.values)
                        DropdownMenuItem(value: a, child: Text(a.label)),
                    ],
                    onChanged: (v) =>
                        v == null ? null : ctl.setDefaultAudioFormat(v),
                  ),
                ),
                _Row(
                  'Default audio bitrate',
                  trailing: DropdownButton<AudioBitrate>(
                    value: s.defaultAudioBitrate,
                    items: [
                      for (final b in AudioBitrate.values)
                        DropdownMenuItem(value: b, child: Text(b.label)),
                    ],
                    onChanged: (v) =>
                        v == null ? null : ctl.setDefaultAudioBitrate(v),
                  ),
                ),
                _Row(
                  'Simultaneous downloads',
                  trailing: DropdownButton<int>(
                    value: s.maxConcurrent,
                    items: [
                      for (var n = 1; n <= 5; n++)
                        DropdownMenuItem(value: n, child: Text('$n')),
                    ],
                    onChanged: (v) =>
                        v == null ? null : ctl.setMaxConcurrent(v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),

          _StorageCard(),
          const SizedBox(height: Spacing.md),

          // Behaviour
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader('Behaviour',
                    icon: Icons.notifications_outlined),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Desktop notifications'),
                  subtitle:
                      const Text('Toast when a download finishes or fails'),
                  value: s.notificationsEnabled,
                  onChanged: (v) {
                    ctl.setNotificationsEnabled(v);
                    ref.read(notificationServiceProvider).enabled = v;
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Minimize to system tray'),
                  subtitle: const Text(
                      'Keep downloading when the window is closed'),
                  value: s.minimizeToTray,
                  onChanged: ctl.setMinimizeToTray,
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),

          _EngineCard(),
          const SizedBox(height: Spacing.md),
          _AboutCard(),
        ],
      ),
    );
  }
}

class _StorageCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_StorageCard> createState() => _StorageCardState();
}

class _StorageCardState extends ConsumerState<_StorageCard> {
  int? _used;
  int? _free;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _compute();
  }

  Future<void> _compute() async {
    final dir = ref.read(settingsControllerProvider).downloadDir;
    if (dir == null) return;
    setState(() => _busy = true);
    final used = await StorageInfo.folderSize(dir);
    final free = await StorageInfo.freeSpace(dir);
    if (mounted) {
      setState(() {
        _used = used;
        _free = free;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsControllerProvider);
    final ctl = ref.read(settingsControllerProvider.notifier);

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('Storage', icon: Icons.sd_storage_outlined),
          _Row(
            'Download folder',
            trailing: TextButton.icon(
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('Change'),
              onPressed: () async {
                final dir = await FilePicker.platform.getDirectoryPath();
                if (dir != null) {
                  await ctl.setDownloadDir(dir);
                  _compute();
                }
              },
            ),
          ),
          Text(s.downloadDir ?? 'Not set',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: Spacing.sm),
          if (_busy)
            const LinearProgressIndicator()
          else
            Wrap(spacing: Spacing.lg, children: [
              _Stat('Used by downloads', Fmt.bytes(_used)),
              _Stat('Free on drive', Fmt.bytes(_free)),
            ]),
          const SizedBox(height: Spacing.sm),
          OutlinedButton.icon(
            icon: const Icon(Icons.cleaning_services_outlined),
            label: const Text('Clear cache (.part / temp files)'),
            onPressed: () async {
              final dir = s.downloadDir;
              if (dir == null) return;
              final n = await StorageInfo.clearTempFiles(dir);
              if (context.mounted) {
                showToast(context, 'Removed $n temp files');
              }
              _compute();
            },
          ),
        ],
      ),
    );
  }
}

class _EngineCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_EngineCard> createState() => _EngineCardState();
}

class _EngineCardState extends ConsumerState<_EngineCard> {
  String? _version;
  bool _updating = false;
  double? _progress;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final v = await ref.read(ytDlpServiceProvider).version();
    if (mounted) setState(() => _version = v);
  }

  Future<void> _update() async {
    setState(() {
      _updating = true;
      _progress = null;
    });
    try {
      await ref.read(engineUpdaterProvider).updateYtDlp(
            onProgress: (p) => mounted ? setState(() => _progress = p) : null,
          );
      await _loadVersion();
      if (mounted) showToast(context, 'Engine updated successfully');
    } catch (e) {
      if (mounted) showToast(context, 'Update failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bin = ref.read(binaryResolverProvider);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('Download engine',
              icon: Icons.bolt_outlined),
          Text('yt-dlp version: ${_version ?? "unknown"}',
              style: Theme.of(context).textTheme.bodyMedium),
          Text(bin.statusReport,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: Spacing.sm),
          if (_updating)
            Row(children: [
              Expanded(child: LinearProgressIndicator(value: _progress)),
              const SizedBox(width: Spacing.sm),
              Text(_progress == null ? '' : Fmt.percent(_progress!)),
            ])
          else
            FilledButton.icon(
              onPressed: _update,
              icon: const Icon(Icons.system_update_alt_rounded),
              label: const Text('Update downloader engine'),
            ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('About', icon: Icons.info_outline_rounded),
          Text('TubeVault 2.0.0', style: t.bodyLarge),
          const SizedBox(height: Spacing.xs),
          Text(
            'A premium YouTube downloader for Windows.\n\n'
            'Powered by yt-dlp (Unlicense) and FFmpeg (LGPL/GPL). '
            'TubeVault is an independent project and is not affiliated with '
            'YouTube or Google.',
            style: t.bodySmall,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Please download only content you own or are permitted to '
            'download, and respect the rights of content owners.',
            style: t.bodySmall?.copyWith(color: Palette.warning),
          ),
          const SizedBox(height: Spacing.sm),
          const Divider(),
          const SizedBox(height: Spacing.xs),
          Row(
            children: [
              Text('Created by ', style: t.bodySmall),
              InkWell(
                mouseCursor: SystemMouseCursors.click,
                borderRadius: const BorderRadius.all(Radii.xs),
                onTap: () => launchUrl(
                  Uri.parse('https://www.jayasakthi.in'),
                  mode: LaunchMode.externalApplication,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Jayasakthi · www.jayasakthi.in',
                    style: t.bodySmall?.copyWith(
                      color: context.accent,
                      fontWeight: FontWeight.w600,
                    ),
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

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch(
      {required this.color, required this.selected, required this.onTap});
  final Color color;
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
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [color, Accents.gradientPartner(color)]),
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? context.scheme.onSurface
                  : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: selected ? Shadows.glow(color) : null,
          ),
          child: selected
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
              : null,
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, {required this.trailing});
  final String label;
  final Widget trailing;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          trailing,
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.55))),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
