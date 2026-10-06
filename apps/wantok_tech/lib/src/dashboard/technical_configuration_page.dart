import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

class TechnicalConfigurationPage extends StatefulWidget {
  const TechnicalConfigurationPage({required this.module, super.key});

  final TechnicalModuleAccess module;

  @override
  State<TechnicalConfigurationPage> createState() =>
      _TechnicalConfigurationPageState();
}

class _TechnicalConfigurationPageState
    extends State<TechnicalConfigurationPage> {
  static const _repository = TechnicalControlRepository();

  late Future<List<TechnicalConfigField>> _future;
  final Map<String, dynamic> _draft = <String, dynamic>{};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _repository.loadModuleConfiguration(widget.module.moduleKey);
  }

  Future<void> _reload() async {
    setState(() {
      _draft.clear();
      _future = _repository.loadModuleConfiguration(widget.module.moduleKey);
    });
    await _future;
  }

  dynamic _displayValue(TechnicalConfigField field) {
    if (_draft.containsKey(field.fieldKey)) {
      final value = _draft[field.fieldKey];
      return value ?? field.defaultValue;
    }
    return field.effectiveValue;
  }

  void _setDraft(TechnicalConfigField field, dynamic value) {
    setState(() => _draft[field.fieldKey] = value);
  }

  void _resetField(TechnicalConfigField field) {
    if (!field.canConfigure || _saving) return;
    setState(() => _draft[field.fieldKey] = null);
  }

  void _discard() {
    if (_saving) return;
    setState(_draft.clear);
  }

  Future<void> _save(List<TechnicalConfigField> fields) async {
    if (_saving || _draft.isEmpty || fields.isEmpty) return;

    final values = <String, dynamic>{};

    try {
      for (final entry in _draft.entries) {
        final field = fields.firstWhere(
          (candidate) => candidate.fieldKey == entry.key,
        );
        values[entry.key] = entry.value == null
            ? null
            : _coerceValue(field, entry.value);
      }
    } on FormatException catch (error) {
      _showMessage(error.message);
      return;
    }

    setState(() => _saving = true);
    try {
      final changed = await _repository.updateModuleConfiguration(
        moduleKey: widget.module.moduleKey,
        schemaVersion: fields.first.schemaVersion,
        values: values,
      );
      await _reload();
      if (mounted) {
        _showMessage(
          changed == 1
              ? '1 configuration setting updated.'
              : '$changed configuration settings updated.',
        );
      }
    } catch (error) {
      if (mounted) _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  dynamic _coerceValue(TechnicalConfigField field, dynamic value) {
    if (field.fieldType == 'boolean') return value as bool;

    final raw = value.toString().trim();

    switch (field.fieldType) {
      case 'integer':
      case 'duration_seconds':
        final parsed = int.tryParse(raw);
        if (parsed == null) {
          throw FormatException('${field.label} must be a whole number.');
        }
        return parsed;

      case 'decimal':
        final parsed = num.tryParse(raw);
        if (parsed == null) {
          throw FormatException('${field.label} must be a number.');
        }
        return parsed;

      case 'string_list':
        if (raw.isEmpty) return <String>[];
        return raw
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false);

      default:
        return raw;
    }
  }

  void _showMessage(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.module.name} configuration'),
        actions: [
          IconButton(
            tooltip: 'Reload',
            onPressed: _saving ? null : _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<TechnicalConfigField>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: _friendlyError(snapshot.error!),
              onRetry: _reload,
            );
          }

          final fields = snapshot.data ?? const <TechnicalConfigField>[];

          if (fields.isEmpty) {
            return _EmptyConfiguration(moduleName: widget.module.name);
          }

          final first = fields.first;
          final canConfigure = first.canConfigure;
          final groups = <String, List<TechnicalConfigField>>{};
          for (final field in fields) {
            groups.putIfAbsent(field.groupKey, () => []).add(field);
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(28),
                  children: [
                    _ConfigurationHeader(
                      module: widget.module,
                      field: first,
                      canConfigure: canConfigure,
                    ),
                    const SizedBox(height: 20),
                    if (!canConfigure)
                      const Card(
                        color: Color(0xFFF4F7F5),
                        child: ListTile(
                          leading: Icon(
                            Icons.visibility_outlined,
                            color: WantokColors.primaryDark,
                          ),
                          title: Text(
                            'Read-only configuration access',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            'You can inspect effective settings but do not '
                            'have module.configure permission.',
                          ),
                        ),
                      ),
                    if (!canConfigure) const SizedBox(height: 14),
                    for (final entry in groups.entries) ...[
                      _ConfigurationGroup(
                        title: entry.value.first.groupLabel,
                        fields: entry.value,
                        canConfigure: canConfigure,
                        saving: _saving,
                        displayValue: _displayValue,
                        onChanged: _setDraft,
                        onReset: _resetField,
                        dirtyKeys: _draft.keys.toSet(),
                      ),
                      const SizedBox(height: 14),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
              if (canConfigure)
                _SaveBar(
                  changedCount: _draft.length,
                  saving: _saving,
                  onDiscard: _draft.isEmpty ? null : _discard,
                  onSave: _draft.isEmpty ? null : () => _save(fields),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ConfigurationHeader extends StatelessWidget {
  const _ConfigurationHeader({
    required this.module,
    required this.field,
    required this.canConfigure,
  });

  final TechnicalModuleAccess module;
  final TechnicalConfigField field;
  final bool canConfigure;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: const Color(0xFFE1F2E8),
          child: const Icon(
            Icons.tune_rounded,
            color: WantokColors.primaryDark,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                field.schemaTitle,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              if (field.schemaDescription != null)
                Text(
                  field.schemaDescription!,
                  style: const TextStyle(color: WantokColors.muted),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.schema_outlined, size: 16),
                    label: Text('Schema v${field.schemaVersion}'),
                  ),
                  Chip(
                    avatar: Icon(
                      canConfigure
                          ? Icons.edit_outlined
                          : Icons.visibility_outlined,
                      size: 16,
                    ),
                    label: Text(canConfigure ? 'Editable' : 'Read only'),
                  ),
                  Chip(
                    avatar: const Icon(Icons.extension_outlined, size: 16),
                    label: Text(module.moduleKey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfigurationGroup extends StatelessWidget {
  const _ConfigurationGroup({
    required this.title,
    required this.fields,
    required this.canConfigure,
    required this.saving,
    required this.displayValue,
    required this.onChanged,
    required this.onReset,
    required this.dirtyKeys,
  });

  final String title;
  final List<TechnicalConfigField> fields;
  final bool canConfigure;
  final bool saving;
  final dynamic Function(TechnicalConfigField field) displayValue;
  final void Function(TechnicalConfigField field, dynamic value) onChanged;
  final ValueChanged<TechnicalConfigField> onReset;
  final Set<String> dirtyKeys;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              '${fields.length} setting${fields.length == 1 ? '' : 's'}',
              style: const TextStyle(color: WantokColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            for (var index = 0; index < fields.length; index++) ...[
              _ConfigFieldEditor(
                field: fields[index],
                value: displayValue(fields[index]),
                enabled: canConfigure && !saving,
                dirty: dirtyKeys.contains(fields[index].fieldKey),
                onChanged: (value) => onChanged(fields[index], value),
                onReset: () => onReset(fields[index]),
              ),
              if (index != fields.length - 1) const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConfigFieldEditor extends StatelessWidget {
  const _ConfigFieldEditor({
    required this.field,
    required this.value,
    required this.enabled,
    required this.dirty,
    required this.onChanged,
    required this.onReset,
  });

  final TechnicalConfigField field;
  final dynamic value;
  final bool enabled;
  final bool dirty;
  final ValueChanged<dynamic> onChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final control = _buildControl(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 7,
                  runSpacing: 6,
                  children: [
                    Text(
                      field.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    if (field.isRequired) const _MiniChip(label: 'Required'),
                    if (field.isAdvanced) const _MiniChip(label: 'Advanced'),
                    if (field.isSecretReference)
                      const _MiniChip(label: 'Secret ref'),
                    if (dirty) const _MiniChip(label: 'Changed'),
                  ],
                ),
              ),
              if (enabled)
                IconButton(
                  tooltip: 'Reset to schema default',
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt_rounded),
                ),
            ],
          ),
          if (field.helpText != null) ...[
            const SizedBox(height: 4),
            Text(
              field.helpText!,
              style: const TextStyle(color: WantokColors.muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          if (field.isSecretReference) ...[
            const _SecretReferenceNotice(),
            const SizedBox(height: 9),
          ],
          control,
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  field.fieldKey,
                  style: const TextStyle(
                    color: WantokColors.muted,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              if (field.isOverridden && !dirty)
                const Text(
                  'Override',
                  style: TextStyle(
                    color: WantokColors.primaryDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                )
              else if (!field.isOverridden && !dirty)
                const Text(
                  'Schema default',
                  style: TextStyle(color: WantokColors.muted, fontSize: 11),
                ),
            ],
          ),
          if (_validationHint(field) case final hint?) ...[
            const SizedBox(height: 3),
            Text(
              hint,
              style: const TextStyle(color: WantokColors.muted, fontSize: 11),
            ),
          ],
          if (field.updatedByName != null && !dirty) ...[
            const SizedBox(height: 3),
            Text(
              'Last changed by ${field.updatedByName}',
              style: const TextStyle(color: WantokColors.muted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControl(BuildContext context) {
    if (field.fieldType == 'boolean') {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: value == true,
        onChanged: enabled ? onChanged : null,
        title: Text(value == true ? 'Enabled' : 'Disabled'),
        dense: true,
      );
    }

    if (field.fieldType == 'enum') {
      final options =
          (field.validation['allowed_values'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(growable: false);
      return DropdownButtonFormField<String>(
        initialValue: value?.toString(),
        decoration: const InputDecoration(prefixIcon: Icon(Icons.rule_rounded)),
        items: options
            .map(
              (option) => DropdownMenuItem(
                value: option,
                child: Text(_prettyValue(option)),
              ),
            )
            .toList(growable: false),
        onChanged: enabled
            ? (selected) {
                if (selected != null) onChanged(selected);
              }
            : null,
      );
    }

    final initial = field.fieldType == 'string_list'
        ? (value is List ? value.join(', ') : value?.toString() ?? '')
        : value?.toString() ?? '';

    return TextFormField(
      key: ValueKey('${field.fieldKey}:$initial'),
      initialValue: initial,
      enabled: enabled,
      minLines: field.fieldType == 'string_list' ? 2 : 1,
      maxLines: field.fieldType == 'string_list' ? 3 : 1,
      keyboardType: switch (field.fieldType) {
        'integer' || 'duration_seconds' => TextInputType.number,
        'decimal' => const TextInputType.numberWithOptions(decimal: true),
        'url' => TextInputType.url,
        _ => TextInputType.text,
      },
      decoration: InputDecoration(
        prefixIcon: Icon(_fieldIcon(field.fieldType)),
        hintText: switch (field.fieldType) {
          'secret_reference' => 'env://SECRET_NAME',
          'url' => 'https://…',
          'string_list' => 'item one, item two',
          _ => null,
        },
      ),
      onChanged: onChanged,
    );
  }
}

class _SecretReferenceNotice extends StatelessWidget {
  const _SecretReferenceNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5DC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.key_rounded, color: Color(0xFF8B6400), size: 19),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Reference only. Never paste the actual secret here. '
              'Use env://, vault://, external-secret:// or supabase://.',
              style: TextStyle(color: Color(0xFF6E5200), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F2EC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: WantokColors.primaryDark,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.changedCount,
    required this.saving,
    required this.onDiscard,
    required this.onSave,
  });

  final int changedCount;
  final bool saving;
  final VoidCallback? onDiscard;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  changedCount == 0
                      ? 'No unsaved changes'
                      : '$changedCount unsaved change${changedCount == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: changedCount == 0
                        ? WantokColors.muted
                        : WantokColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: saving ? null : onDiscard,
                child: const Text('Discard'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: saving ? null : onSave,
                icon: saving
                    ? const SizedBox.square(
                        dimension: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(saving ? 'Saving…' : 'Save configuration'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyConfiguration extends StatelessWidget {
  const _EmptyConfiguration({required this.moduleName});

  final String moduleName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.tune_rounded,
                  size: 52,
                  color: WantokColors.muted,
                ),
                const SizedBox(height: 12),
                Text(
                  'No configuration schema yet',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  '$moduleName does not yet expose safe typed settings. '
                  'This module can still be managed through its existing '
                  'state and permission controls.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: WantokColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: WantokColors.coral,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Could not load module configuration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 7),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _fieldIcon(String type) {
  return switch (type) {
    'boolean' => Icons.toggle_on_outlined,
    'integer' => Icons.onetwothree_rounded,
    'decimal' => Icons.numbers_rounded,
    'duration_seconds' => Icons.timer_outlined,
    'enum' => Icons.rule_rounded,
    'url' => Icons.link_rounded,
    'string_list' => Icons.format_list_bulleted_rounded,
    'secret_reference' => Icons.key_rounded,
    _ => Icons.text_fields_rounded,
  };
}

String? _validationHint(TechnicalConfigField field) {
  final validation = field.validation;
  final parts = <String>[];

  if (validation['min'] != null || validation['max'] != null) {
    final min = validation['min'];
    final max = validation['max'];
    if (min != null && max != null) {
      parts.add('Allowed: $min–$max');
    } else if (min != null) {
      parts.add('Minimum: $min');
    } else if (max != null) {
      parts.add('Maximum: $max');
    }
  }

  if (validation['max_items'] != null) {
    parts.add('Up to ${validation['max_items']} items');
  }

  if (validation['max_length'] != null) {
    parts.add('Max ${validation['max_length']} characters');
  }

  return parts.isEmpty ? null : parts.join(' • ');
}

String _prettyValue(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _friendlyError(Object error) {
  final raw = error.toString();
  final messageMatch = RegExp(r'message:\s*([^,\)]+)').firstMatch(raw);
  if (messageMatch != null) return messageMatch.group(1)!.trim();
  return raw.replaceFirst('StateError: ', '');
}
