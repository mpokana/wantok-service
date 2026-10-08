import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'provider_discovery_page.dart';
import 'wantok_category_ui.dart';

/// Real catalogue detail: approved provider search plus an explicitly
/// non-commercial interest register. No booking, approval or payment actions.
class CategoryInformationPage extends StatefulWidget {
  const CategoryInformationPage({
    super.key,
    required this.style,
    required this.description,
    this.categoryId,
    this.registerInterest,
    this.loadInterest,
  });

  final WantokCategoryStyle style;
  final String description;
  final String? categoryId;

  /// Injected only for deterministic widget tests.
  final Future<void> Function(String slug)? registerInterest;
  final Future<bool> Function(String categoryId)? loadInterest;

  @override
  State<CategoryInformationPage> createState() =>
      _CategoryInformationPageState();
}

class _CategoryInformationPageState extends State<CategoryInformationPage> {
  static const _interest = ProviderCategoryInterestRepository();
  bool _registered = false;
  bool _loading = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.categoryId != null) _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    try {
      final value =
          await (widget.loadInterest ?? _interest.hasRegisteredInterest)(
            widget.categoryId!,
          );
      if (mounted) setState(() => _registered = value);
    } catch (_) {
      // Discovery does not depend on the optional waitlist/read status.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    if (_submitting || _registered || widget.categoryId == null) return;
    setState(() => _submitting = true);
    try {
      await (widget.registerInterest ?? _interest.registerInterest)(
        widget.style.slug,
      );
      if (mounted) setState(() => _registered = true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is StateError
                  ? error.message.toString()
                  : 'Could not register interest. Please sign in or try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _browseProviders() {
    final categoryId = widget.categoryId;
    if (categoryId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProviderDiscoveryPage(
          initialCategoryId: categoryId,
          initialCategoryName: widget.style.title.replaceAll('\n', ' '),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAFD),
    appBar: AppBar(
      title: Text(widget.style.title.replaceAll('\n', ' ')),
      backgroundColor: Colors.white,
      foregroundColor: WantokColors.ink,
    ),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        AspectRatio(
          aspectRatio: 1.85,
          child: WantokCategoryPicture(style: widget.style, borderRadius: 22),
        ),
        const SizedBox(height: 18),
        Text(
          widget.style.title.replaceAll('\n', ' '),
          style: const TextStyle(
            fontSize: 25,
            color: WantokColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.description,
          style: const TextStyle(
            fontSize: 14,
            color: WantokColors.muted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFFE4EAF3)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Padding(
            padding: EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: WantokColors.primary,
                  size: 23,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Provider listings coming soon',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'This category is in the Wantok catalogue. '
                        'Only active, verified providers with approved services '
                        'can appear in search. No booking or payment is enabled '
                        'from this page.',
                        style: TextStyle(
                          color: WantokColors.muted,
                          height: 1.45,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.categoryId != null) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey('category-verified-providers'),
            onPressed: _browseProviders,
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Browse verified providers'),
          ),
          const SizedBox(height: 16),
          Text(
            'Interested in providing this service?',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Register your interest using your signed-in Wantok account. '
            'This is not a provider application, licence verification or '
            'approval. It does not create a provider listing or guarantee '
            'contact, notification or onboarding.',
            style: TextStyle(
              fontSize: 12,
              color: WantokColors.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const ValueKey('category-provider-interest'),
            onPressed: _loading || _submitting || _registered
                ? null
                : _register,
            icon: _loading || _submitting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _registered
                        ? Icons.check_circle_outline
                        : Icons.person_add_alt_1,
                  ),
            label: Text(
              _registered ? 'Interest recorded' : 'Register provider interest',
            ),
          ),
          if (_registered)
            const Padding(
              padding: EdgeInsets.only(top: 7),
              child: Text(
                'Received. No further action is needed at this stage.',
                style: TextStyle(fontSize: 12, color: WantokColors.muted),
              ),
            ),
        ],
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Browse other services'),
        ),
      ],
    ),
  );
}
