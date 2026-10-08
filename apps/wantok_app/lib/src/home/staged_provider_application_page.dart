import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

/// Controlled preliminary intake. Never creates a verified vendor.
class StagedProviderApplicationPage extends StatefulWidget {
  const StagedProviderApplicationPage({
    super.key,
    required this.categoryId,
    required this.categorySlug,
    required this.categoryName,
    required this.requirements,
    this.loadApplication,
    this.submitApplication,
  });

  final String categoryId;
  final String categorySlug;
  final String categoryName;
  final List<String> requirements;
  final Future<Map<String, dynamic>?> Function(String)? loadApplication;
  final Future<void> Function(String, String, String, String, String, String)?
  submitApplication;

  @override
  State<StagedProviderApplicationPage> createState() =>
      _StagedProviderApplicationPageState();
}

class _StagedProviderApplicationPageState
    extends State<StagedProviderApplicationPage> {
  static const _repo = StagedOnboardingRepository();
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _province = TextEditingController();
  final _town = TextEditingController();
  final _summary = TextEditingController();
  String _kind = 'individual';
  bool _sending = false;
  late Future<Map<String, dynamic>?> _existing;

  @override
  void initState() {
    super.initState();
    _existing = (widget.loadApplication ?? _repo.loadMyApplication)(
      widget.categoryId,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _province.dispose();
    _town.dispose();
    _summary.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending || !(_form.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    try {
      if (widget.submitApplication != null) {
        await widget.submitApplication!(
          widget.categorySlug,
          _name.text.trim(),
          _kind,
          _province.text.trim(),
          _town.text.trim(),
          _summary.text.trim(),
        );
      } else {
        await _repo.submit(
          categorySlug: widget.categorySlug,
          applicantName: _name.text.trim(),
          applicantKind: _kind,
          province: _province.text.trim(),
          town: _town.text.trim(),
          summary: _summary.text.trim(),
        );
      }
      if (mounted) {
        setState(() {
          _existing = Future.value(<String, dynamic>{
            'status': 'submitted',
            'applicant_name': _name.text.trim(),
            'coverage_province': _province.text.trim(),
          });
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not submit. Please check your details, sign-in and connection.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String? _requiredField(String? value, {int minimum = 2, int maximum = 120}) {
    final text = (value ?? '').trim();
    if (text.length < minimum || text.length > maximum) {
      return 'Enter between $minimum and $maximum characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Preliminary provider application')),
    backgroundColor: const Color(0xFFF8FAFD),
    body: FutureBuilder<Map<String, dynamic>?>(
      future: _existing,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton.icon(
              onPressed: () => setState(
                () => _existing =
                    (widget.loadApplication ?? _repo.loadMyApplication)(
                      widget.categoryId,
                    ),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry loading application'),
            ),
          );
        }
        final existing = snapshot.data;
        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              widget.categoryName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: WantokColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This is a preliminary review request, not approval. '
              'Wantok cannot activate provider services or accept payments '
              'until full eligibility and verification checks are separately completed.',
              style: TextStyle(color: WantokColors.muted, height: 1.45),
            ),
            const SizedBox(height: 15),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Future verification checklist',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 9),
                    for (final item in widget.requirements)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.fact_check_outlined,
                              color: WantokColors.primary,
                              size: 19,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Text(
                      'Do not upload sensitive identity or licence documents here.',
                      style: TextStyle(fontSize: 11, color: WantokColors.muted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (existing != null) ...[
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.pending_actions_rounded,
                    color: WantokColors.primary,
                  ),
                  title: Text(
                    'Application: ${existing['status'] ?? 'submitted'}',
                  ),
                  subtitle: Text(
                    'Received for ${existing['applicant_name'] ?? widget.categoryName}. '
                    'This is not provider approval.',
                  ),
                ),
              ),
            ] else ...[
              Form(
                key: _form,
                child: Column(
                  children: [
                    TextFormField(
                      key: const ValueKey('staged-applicant-name'),
                      controller: _name,
                      maxLength: 120,
                      decoration: const InputDecoration(
                        labelText: 'Name or business name',
                      ),
                      validator: (v) => _requiredField(v),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _kind,
                      decoration: const InputDecoration(
                        labelText: 'Applicant type',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'individual',
                          child: Text('Individual'),
                        ),
                        DropdownMenuItem(
                          value: 'business',
                          child: Text('Business'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _kind = v ?? 'individual'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      key: const ValueKey('staged-applicant-province'),
                      controller: _province,
                      maxLength: 90,
                      decoration: const InputDecoration(
                        labelText: 'Service province / region',
                      ),
                      validator: (v) => _requiredField(v, maximum: 90),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _town,
                      maxLength: 90,
                      decoration: const InputDecoration(
                        labelText: 'Town (optional)',
                      ),
                      validator: (v) => (v?.trim().isEmpty ?? true)
                          ? null
                          : _requiredField(v, maximum: 90),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      key: const ValueKey('staged-applicant-summary'),
                      controller: _summary,
                      maxLength: 1000,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText:
                            'Describe the service you propose to provide',
                      ),
                      validator: (v) =>
                          _requiredField(v, minimum: 10, maximum: 1000),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const ValueKey('submit-staged-application'),
                      onPressed: _sending ? null : _submit,
                      icon: _sending
                          ? const SizedBox(
                              height: 17,
                              width: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined),
                      label: const Text('Submit for preliminary review'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    ),
  );
}
