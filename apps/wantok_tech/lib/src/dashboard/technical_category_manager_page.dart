import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

/// Editorial control lives in Technical only. RPCs verify the authenticated
/// Technical Platform Administrator even when UI routes are opened directly.
class TechnicalCategoryManagerPage extends StatefulWidget {
  const TechnicalCategoryManagerPage({super.key, this.loadCategories});

  final Future<List<ManagedServiceCategory>> Function()? loadCategories;

  @override
  State<TechnicalCategoryManagerPage> createState() =>
      _TechnicalCategoryManagerPageState();
}

class _TechnicalCategoryManagerPageState
    extends State<TechnicalCategoryManagerPage> {
  static const _repo = CategoryManagementRepository();
  late Future<List<ManagedServiceCategory>> _categories;
  bool _busy = false;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _categories = _load();
  }

  Future<List<ManagedServiceCategory>> _load() =>
      widget.loadCategories?.call() ?? _repo.loadAll();

  void _refresh() => setState(() => _categories = _load());

  void _notice(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _edit(ManagedServiceCategory? item) async {
    if (_busy) return;
    final fields = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _CategoryEditorDialog(initial: item),
    );
    if (fields == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _repo.save(fields, existing: item);
      _notice(
        item == null
            ? 'Category added as configured.'
            : 'Category updated. Refresh Client to see the changes.',
      );
      _refresh();
    } catch (error) {
      _notice('Category not saved: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(
    ManagedServiceCategory item, {
    required bool delete,
  }) async {
    if (_busy) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(delete ? 'Delete unused draft?' : 'Archive category?'),
        content: Text(
          delete
              ? 'Only inactive categories without provider, intake or booking '
                    'references can be deleted. A referenced category must be archived.'
              : 'This immediately hides ${item.name} from Home and Services. '
                    'Existing provider and booking records stay intact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(delete ? 'Delete draft' : 'Archive'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => _busy = true);
    try {
      if (delete) {
        await _repo.removeUnusedDraft(item);
      } else {
        await _repo.archive(item);
      }
      _notice(delete ? 'Unused draft deleted.' : 'Category archived.');
      _refresh();
    } catch (error) {
      _notice('Operation blocked: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Service categories'),
      actions: [
        IconButton(
          tooltip: 'Refresh categories',
          onPressed: _busy ? null : _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1250),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary
                        .withValues(alpha: .98),
                    const Color(0xFF087453),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WANTOK PLATFORM ENGINEERING',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Service category management',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'One governed catalogue, consistent photographs '
                    'and visibility across Client Web and Android.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 340,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search categories',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) =>
                        setState(() => _filter = value.toLowerCase()),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _busy ? null : () => _edit(null),
                  icon: const Icon(Icons.add),
                  label: const Text('Add category'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<ManagedServiceCategory>>(
              future: _categories,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  if (snapshot.hasError) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Could not load categories. Retry.\n${snapshot.error}',
                        ),
                      ),
                    );
                  }
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final shown = snapshot.data!
                    .where(
                      (item) =>
                          item.name.toLowerCase().contains(_filter) ||
                          item.slug.contains(_filter),
                    )
                    .toList();
                return Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${shown.length} of ${snapshot.data!.length} categories',
                        style: const TextStyle(color: WantokColors.muted),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _CategoryMetric(
                          label: 'All categories',
                          value: snapshot.data!.length,
                          icon: Icons.category_outlined,
                        ),
                        _CategoryMetric(
                          label: 'Active services',
                          value: snapshot.data!.where((c) => c.isActive).length,
                          icon: Icons.check_circle_outline,
                        ),
                        _CategoryMetric(
                          label: 'Pending review',
                          value: snapshot.data!
                              .where((c) => !c.isActive)
                              .length,
                          icon: Icons.pending_actions_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    for (final item in shown)
                      Card(
                        key: ValueKey('category-${item.slug}'),
                        color: Theme.of(context).cardTheme.color,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: LayoutBuilder(
                            builder: (context, limits) {
                              final details = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    item.slug,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: WantokColors.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      _CategoryStatusChip(
                                        label: item.isActive
                                            ? 'Active'
                                            : 'Draft',
                                        highlighted: item.isActive,
                                      ),
                                      _CategoryStatusChip(
                                        label:
                                            'Home ${item.showOnHome ? 'On' : 'Off'}',
                                        highlighted:
                                            item.isActive && item.showOnHome,
                                      ),
                                      _CategoryStatusChip(
                                        label:
                                            'Services ${item.showInServices ? 'On' : 'Off'}',
                                        highlighted:
                                            item.isActive &&
                                            item.showInServices,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.bookingMode} · Display order ${item.sortOrder}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: WantokColors.muted,
                                    ),
                                  ),
                                ],
                              );
                              final controls = Wrap(
                                spacing: 4,
                                children: [
                                  IconButton(
                                    tooltip: 'Edit ${item.name}',
                                    onPressed: _busy ? null : () => _edit(item),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Archive ${item.name}',
                                    onPressed: _busy
                                        ? null
                                        : () => _remove(item, delete: false),
                                    icon: const Icon(Icons.archive_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete unused ${item.name}',
                                    onPressed: _busy
                                        ? null
                                        : () => _remove(item, delete: true),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              );
                              final scope = WantokBrandingScope.maybeOf(
                                context,
                              );
                              final published =
                                  scope?.mediaUrl(item.slug, 'homeIcon') ??
                                  scope?.mediaUrl(item.slug, 'cardImage');
                              final photo =
                                  published ??
                                  (item.imagePath == null
                                      ? null
                                      : BrandingRepository.imageUrl(
                                          item.imagePath!,
                                        ));
                              final preview = SizedBox(
                                width: limits.maxWidth < 650 ? 100 : 142,
                                height: limits.maxWidth < 650 ? 70 : 86,
                                child: WantokCategoryMedia.picture(
                                  item.slug,
                                  uploadedUrl: photo,
                                ),
                              );
                              if (limits.maxWidth < 650) {
                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        preview,
                                        const SizedBox(width: 12),
                                        Expanded(child: details),
                                      ],
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: controls,
                                    ),
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  preview,
                                  const SizedBox(width: 16),
                                  Expanded(child: details),
                                  controls,
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _CategoryEditorDialog extends StatefulWidget {
  const _CategoryEditorDialog({required this.initial});
  final ManagedServiceCategory? initial;

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  late final _slug = TextEditingController(text: widget.initial?.slug ?? '');
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _description = TextEditingController(
    text: widget.initial?.description ?? '',
  );
  late final _order = TextEditingController(
    text: '${widget.initial?.sortOrder ?? 500}',
  );
  String _vertical = 'people';
  String _booking = 'information';
  bool _active = false;
  bool _home = false;
  bool _services = false;
  String? _path;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _vertical = widget.initial?.vertical ?? 'people';
    _booking = widget.initial?.bookingMode ?? 'information';
    _active = widget.initial?.isActive ?? false;
    _home = widget.initial?.showOnHome ?? false;
    _services = widget.initial?.showInServices ?? false;
    _path = widget.initial?.imagePath;
  }

  @override
  void dispose() {
    _slug.dispose();
    _name.dispose();
    _description.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _pickPicture() async {
    final slug = _slug.text.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(slug)) {
      setState(() => _error = 'Enter a valid category slug first.');
      return;
    }
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final extension = file.name.split('.').last.toLowerCase();
    if (!const {'jpg', 'png', 'webp'}.contains(extension)) {
      setState(() => _error = 'Choose JPG, PNG or WebP.');
      return;
    }
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final path = await const BrandingRepository().upload(
        slug: slug,
        slot: 'cardImage',
        extension: extension,
        bytes: bytes,
      );
      if (mounted) {
        setState(() {
          _path = path;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'Image not uploaded: $error');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _save() {
    final slug = _slug.text.trim().toLowerCase();
    final name = _name.text.trim();
    final order = int.tryParse(_order.text.trim());
    if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(slug) ||
        name.length < 2 ||
        order == null ||
        order < 0 ||
        order > 9999) {
      setState(() => _error = 'Valid slug, name and order are required.');
      return;
    }
    Navigator.of(context).pop(<String, dynamic>{
      'slug': slug,
      'name': name,
      'description': _description.text.trim(),
      'vertical': _vertical,
      'booking_mode': _booking,
      'is_active': _active,
      'show_on_home': _home,
      'show_in_services': _services,
      'sort_order': order,
      'image_path': _path,
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initial == null ? 'Add category' : 'Edit category'),
    content: SizedBox(
      width: 570,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Categories are shared between app and Web. New slugs '
              'cannot be changed after creation. Upload a unique category photo '
              'before enabling a new service.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _slug,
              enabled: widget.initial == null,
              decoration: const InputDecoration(labelText: 'Slug'),
            ),
            TextField(
              controller: _description,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _vertical,
              decoration: const InputDecoration(labelText: 'Service family'),
              items: const [
                'mobility',
                'delivery',
                'hire',
                'people',
                'places',
                'events',
                'food',
                'shopping',
                'travel',
                'other',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _vertical = v);
                }
              },
            ),
            DropdownButtonFormField<String>(
              initialValue: _booking,
              decoration: const InputDecoration(labelText: 'Booking mode'),
              items: const [
                'information',
                'quote',
                'scheduled',
                'on_demand',
                'reservation',
                'commerce',
                'ticketing',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _booking = v);
                }
              },
            ),
            TextField(
              controller: _order,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sort order'),
            ),
            SwitchListTile(
              title: const Text('Enabled / active'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            SwitchListTile(
              title: const Text('Show on Home'),
              value: _home,
              onChanged: (v) => setState(() => _home = v),
            ),
            SwitchListTile(
              title: const Text('Show in Services'),
              value: _services,
              onChanged: (v) => setState(() => _services = v),
            ),
            OutlinedButton.icon(
              onPressed: _uploading ? null : _pickPicture,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                _uploading
                    ? 'Uploading…'
                    : _path == null
                    ? 'Upload category picture'
                    : 'Replace picture',
              ),
            ),
            if (_path != null) ...[
              Text(
                'Uploaded: $_path',
                maxLines: 2,
                style: const TextStyle(fontSize: 11),
              ),
              SizedBox(
                height: 105,
                child: Image.network(
                  BrandingRepository.imageUrl(_path!),
                  fit: BoxFit.contain,
                ),
              ),
            ],
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _uploading ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _uploading ? null : _save,
        child: const Text('Save category'),
      ),
    ],
  );
}

class _CategoryMetric extends StatelessWidget {
  const _CategoryMetric({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 215,
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
    decoration: BoxDecoration(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: .11),
      ),
    ),
    child: Row(
      children: [
        Icon(icon, size: 25, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: WantokColors.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CategoryStatusChip extends StatelessWidget {
  const _CategoryStatusChip({required this.label, required this.highlighted});
  final String label;
  final bool highlighted;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: highlighted
          ? Theme.of(context).colorScheme.primary.withValues(alpha: .09)
          : Theme.of(context).colorScheme.onSurface.withValues(alpha: .055),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 11,
        color: highlighted
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: .7),
      ),
    ),
  );
}
