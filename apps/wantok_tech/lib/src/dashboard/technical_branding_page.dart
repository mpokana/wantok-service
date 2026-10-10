import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

/// Appearance operations are guarded again by database-side RBAC.
/// Changes are only visible to customers after Publish, never Save or Preview.
class TechnicalBrandingPage extends StatefulWidget {
  const TechnicalBrandingPage({super.key});

  @override
  State<TechnicalBrandingPage> createState() => _TechnicalBrandingPageState();
}

class _TechnicalBrandingPageState extends State<TechnicalBrandingPage> {
  static const _repo = BrandingRepository();
  static const _categories = <String, String>{
    'taxi-ride': 'Taxi / Transport',
    'vehicle-hire': 'Hire Car',
    'food': 'Food',
    'groceries': 'Groceries',
    'delivery': 'Delivery',
    'travel-flights': 'Travel & Flights',
    'specialist-services': 'Specialists',
    'public-services': 'Public Services',
    'public-emergency-safety': 'Public / Emergency & Safety',
    'public-health-services': 'Public / Health Services',
    'public-government-services': 'Public / Government Services',
    'public-community-services': 'Public / Community Services',
    'shopping-retail': 'Shopping & Retail',
    'home-services': 'Home Services',
    'beauty-wellness': 'Beauty & Wellness',
    'health-medical': 'Health & Medical',
    'events': 'Events & Tickets',
    'accommodation': 'Hotels',
    'education-training': 'Education & Training',
    'financial-services': 'Financial Services',
    'boat-ship-rides': 'Water Transport',
    'general-labour': 'General Labour',
  };
  late Future<BrandingWorkspace> _future = _repo.getWorkspace();
  BrandingWorkspace? _current;
  Map<String, dynamic> _draft = {};
  bool _busy = false;
  bool _unsaved = false;
  int _editCounter = 0;
  int _previewedCounter = -1;
  String _category = 'public-services';
  String _device = 'mobile';

  Map<String, dynamic> _clone(Map<String, dynamic> value) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);

  Map<String, dynamic> get _theme =>
      Map<String, dynamic>.from(_draft['theme'] as Map? ?? {});
  Map<String, dynamic> get _media =>
      Map<String, dynamic>.from(_draft['media'] as Map? ?? {});

  void _editTheme(String key, dynamic value) {
    setState(() {
      _draft['theme'] = {..._theme, key: value};
      _unsaved = true;
      _editCounter++;
    });
  }

  void _editMedia(String category, String slot, String? path) {
    final media = _media;
    final entry = Map<String, dynamic>.from(media[category] as Map? ?? {});
    if (path == null) {
      entry.remove(slot);
    } else {
      entry[slot] = path;
    }
    if (entry.isEmpty) {
      media.remove(category);
    } else {
      media[category] = entry;
    }
    setState(() {
      _draft['media'] = media;
      _unsaved = true;
      _editCounter++;
    });
  }

  Future<void> _reload() async {
    if (_busy) return;
    setState(() {
      _current = null;
      _future = _repo.getWorkspace();
      _unsaved = false;
      _previewedCounter = -1;
    });
  }

  Future<void> _saveDraft() async {
    if (_busy || !_unsaved || _current == null) return;
    setState(() => _busy = true);
    try {
      final revision = await _repo.saveDraft(_draft, _current!.draftRevision);
      if (!mounted) return;
      final current = _current!;
      setState(() {
        _current = BrandingWorkspace(
          draft: _clone(_draft),
          published: current.published,
          version: current.version,
          draftRevision: revision,
        );
        _unsaved = false;
      });
      _message('Draft saved. Published appearance remains unchanged.');
    } catch (e) {
      if (mounted) _message('Draft not saved: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _preview() async {
    if (_current == null) return;
    setState(() => _previewedCounter = _editCounter);
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1150, maxHeight: 850),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Draft preview — not published',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close preview',
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 9,
                    children: [
                      for (final device in ['desktop', 'tablet', 'mobile'])
                        ChoiceChip(
                          label: Text(device.toUpperCase()),
                          selected: _device == device,
                          onSelected: (_) {
                            setState(() => _device = device);
                            update(() {});
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Center(
                        child: BrandingDevicePreview(
                          document: _draft,
                          device: _device,
                          category: _category,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _publish() async {
    if (_busy ||
        _current == null ||
        _unsaved ||
        _previewedCounter != _editCounter) {
      _message('Save your draft and open Preview before publishing.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publish appearance to all clients?'),
        content: const Text(
          'Only this action changes the published appearance. '
          'Desktop, tablet and mobile users receive it on their next refresh. '
          'The previous version remains available for rollback.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Publish now'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final version = await _repo.publish(
        _current!.version,
        _current!.draftRevision,
      );
      if (!mounted) return;
      _message('Version $version published. Refresh clients to view.');
      setState(() {
        _current = null;
        _future = _repo.getWorkspace();
        _previewedCounter = -1;
      });
    } catch (e) {
      if (mounted) _message('Publish failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    if (_busy || _current == null) return;
    final controller = TextEditingController();
    final target = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore a published version'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Previous version (1–${_current!.version - 1})',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text)),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (target == null || target < 1 || target >= _current!.version) {
      _message('Invalid version.');
      return;
    }
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Restore version $target?'),
        content: const Text(
          'This publishes the previous settings as a new version. '
          'Current published settings remain in history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _repo.restore(target, _current!.version);
      if (!mounted) return;
      setState(() => _current = null);
      _future = _repo.getWorkspace();
      _message('Previous appearance restored.');
    } catch (e) {
      if (mounted) _message('Restore failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upload(String slot) async {
    if (_busy) return;
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > 3145728 || bytes.isEmpty) {
      _message('Image must be under 3 MB.');
      return;
    }
    final isJpeg = bytes.length > 2 && bytes[0] == 0xff && bytes[1] == 0xd8;
    final isPng = bytes.length > 8 && bytes[0] == 0x89 && bytes[1] == 0x50;
    final isWebp =
        bytes.length > 12 &&
        String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP';
    final ext = isJpeg
        ? 'jpg'
        : isPng
        ? 'png'
        : isWebp
        ? 'webp'
        : null;
    if (ext == null) {
      _message('Unsupported image. Choose a valid JPEG, PNG or WebP.');
      return;
    }
    setState(() => _busy = true);
    try {
      final path = await _repo.upload(
        slug: _category,
        slot: slot,
        extension: ext,
        bytes: bytes,
      );
      if (mounted) {
        _editMedia(_category, slot, path);
        _message('Image added to draft. Save, preview and publish to apply.');
      }
    } catch (e) {
      if (mounted) _message('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Theme & Media Management')),
    body: FutureBuilder<BrandingWorkspace>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Technical access or loading failed: ${snapshot.error}',
            ),
          );
        }
        final loaded = snapshot.data!;
        if (!identical(_current, loaded) && _current == null) {
          _current = loaded;
          _draft = _clone(loaded.draft);
          _unsaved = false;
        }
        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              'Draft → Preview → Publish',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              'Published version ${_current?.version ?? loaded.version} · '
              'draft revision ${_current?.draftRevision ?? loaded.draftRevision}. '
              'Nothing here changes customers until you publish.',
            ),
            const SizedBox(height: 16),
            _themeControls(),
            const SizedBox(height: 15),
            _mediaControls(),
            const SizedBox(height: 15),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 9,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _reload,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reload'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () {
                              setState(() {
                                _draft = _clone(
                                  BrandingRepository.defaultDocument,
                                );
                                _unsaved = true;
                                _editCounter++;
                              });
                            },
                      icon: const Icon(Icons.settings_backup_restore),
                      label: const Text('Restore defaults to draft'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _restore,
                      icon: const Icon(Icons.history),
                      label: const Text('Rollback version'),
                    ),
                    FilledButton.icon(
                      onPressed: _busy || !_unsaved ? null : _saveDraft,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save draft'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _preview,
                      icon: const Icon(Icons.devices),
                      label: const Text('Preview devices'),
                    ),
                    FilledButton.icon(
                      onPressed:
                          _busy || _unsaved || _previewedCounter != _editCounter
                          ? null
                          : _publish,
                      icon: const Icon(Icons.publish),
                      label: const Text('Publish'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Only technical platform administrators can save or publish. '
              'Uploaded images are immutable. Old images remain available for rollback. '
              'Preview and Save do not affect live clients.',
              style: TextStyle(color: WantokColors.muted, fontSize: 12),
            ),
          ],
        );
      },
    ),
  );

  Widget _themeControls() {
    final theme = _theme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Theme Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<String>(
                  value: theme['mode']?.toString() ?? 'light',
                  items: ['light', 'dark', 'system']
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text('Appearance: $v'),
                        ),
                      )
                      .toList(),
                  onChanged: _busy
                      ? null
                      : (v) {
                          if (v != null) _editTheme('mode', v);
                        },
                ),
                for (final field in ['primary', 'secondary'])
                  SizedBox(
                    width: 190,
                    child: TextFormField(
                      key: ValueKey('theme-$field-${theme[field]}'),
                      initialValue: theme[field]?.toString(),
                      maxLength: 7,
                      decoration: InputDecoration(
                        labelText: '$field colour (#RRGGBB)',
                        counterText: '',
                      ),
                      onChanged: (v) {
                        if (RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(v)) {
                          _editTheme(field, v);
                        }
                      },
                    ),
                  ),
                SizedBox(
                  width: 215,
                  child: Column(
                    children: [
                      Text('Card radius: ${theme['cardRadius'] ?? 18}'),
                      Slider(
                        value: ((theme['cardRadius'] as num?)?.toDouble() ?? 18)
                            .clamp(8, 30),
                        min: 8,
                        max: 30,
                        divisions: 22,
                        onChanged: _busy
                            ? null
                            : (v) => _editTheme('cardRadius', v.round()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mediaControls() {
    final selected = Map<String, dynamic>.from(_media[_category] as Map? ?? {});
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Media & Icons',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'One independent image for each placement. Existing app '
              'pictures remain the default until a replacement is published.',
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              value: _category,
              isExpanded: true,
              items: _categories.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: _busy
                  ? null
                  : (v) {
                      if (v != null) setState(() => _category = v);
                    },
            ),
            for (final slot in ['homeIcon', 'cardImage', 'bannerImage'])
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.image_outlined),
                title: Text(switch (slot) {
                  'homeIcon' => 'Home tile icon',
                  'cardImage' => 'Services card image',
                  _ => 'Module banner image',
                }),
                subtitle: Text(
                  selected[slot] == null
                      ? 'Bundled default'
                      : 'Draft replacement: ${selected[slot]}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Wrap(
                  spacing: 5,
                  children: [
                    IconButton(
                      tooltip: 'Upload $slot',
                      onPressed: _busy ? null : () => _upload(slot),
                      icon: const Icon(Icons.upload_file),
                    ),
                    IconButton(
                      tooltip: 'Reset $slot to bundled default',
                      onPressed: _busy || selected[slot] == null
                          ? null
                          : () => _editMedia(_category, slot, null),
                      icon: const Icon(Icons.restore),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Layout preview is deliberately local and never modifies published settings.
class BrandingDevicePreview extends StatelessWidget {
  const BrandingDevicePreview({
    required this.document,
    required this.device,
    required this.category,
    super.key,
  });
  final Map<String, dynamic> document;
  final String device, category;

  @override
  Widget build(BuildContext context) {
    final width = switch (device) {
      'desktop' => 990.0,
      'tablet' => 690.0,
      _ => 355.0,
    };
    final theme = WantokBrandingTheme.from(
      document,
      dark: WantokBrandingTheme.mode(document) == ThemeMode.dark,
    );
    final colors = theme.colorScheme;
    final media = Map<String, dynamic>.from(document['media'] as Map? ?? {});
    final current = Map<String, dynamic>.from(media[category] as Map? ?? {});
    Widget visual(String slot, IconData icon) {
      final path = current[slot];
      if (path is String) {
        return Image.network(
          BrandingRepository.imageUrl(path),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              Icon(icon, size: 40, color: colors.primary),
        );
      }
      return Icon(icon, size: 40, color: colors.primary);
    }

    return SizedBox(
      width: width,
      child: Theme(
        data: theme,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.explore, color: colors.primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Wantok Services',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      device.toUpperCase(),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: const SizedBox(
                      width: double.infinity,
                      child: Text(
                        'People. Places. Possibilities.',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Popular categories',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 3,
                  runSpacing: 8,
                  children: [
                    for (final entry in [
                      ('Taxi / Transport', Icons.local_taxi),
                      ('Food', Icons.restaurant),
                      (category.replaceAll('-', ' '), Icons.account_balance),
                    ])
                      SizedBox(
                        width: device == 'mobile' ? 94 : 145,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 60,
                                    child:
                                        entry.$1 ==
                                            category.replaceAll('-', ' ')
                                        ? visual('homeIcon', entry.$2)
                                        : Icon(
                                            entry.$2,
                                            size: 35,
                                            color: colors.primary,
                                          ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    entry.$1,
                                    maxLines: 2,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Services',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 155,
                  child: Card(
                    child: Column(
                      children: [
                        Expanded(
                          child: SizedBox(
                            width: double.infinity,
                            child: visual('cardImage', Icons.image_outlined),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(category.replaceAll('-', ' ')),
                        ),
                      ],
                    ),
                  ),
                ),
                if (current['bannerImage'] != null) ...[
                  const SizedBox(height: 10),
                  const Text('Banner preview'),
                  SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: visual('bannerImage', Icons.image_outlined),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
