import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

import 'provider_application_page.dart';
import 'vendor_case_reply_dialog.dart';
import 'vendor_evidence_inbox_page.dart';

/// International vendor intake. A submission is NOT KYC clearance, provider
/// approval or a permission to offer rides, sell goods or receive payouts.
class VendorEnterpriseApplicationPage extends StatefulWidget {
  const VendorEnterpriseApplicationPage({
    super.key,
    this.loadCategories,
    this.submitForReview,
  });
  final Future<List<Map<String, dynamic>>> Function()? loadCategories;
  final Future<String> Function(Map<String, dynamic> payload)? submitForReview;
  @override
  State<VendorEnterpriseApplicationPage> createState() =>
      _VendorEnterpriseApplicationPageState();
}

class _VendorEnterpriseApplicationPageState
    extends State<VendorEnterpriseApplicationPage> {
  final _stepForms = List.generate(4, (_) => GlobalKey<FormState>());
  final Map<String, TextEditingController> _inputs = {};
  late Future<List<Map<String, dynamic>>> _categories;
  int _step = 0;
  String _kind = 'individual';
  String _identityType = 'national_id';
  String _countryCode = 'PG', _countryName = 'Papua New Guinea';
  Map<String, dynamic>? _category;
  bool _consent = false, _busy = false;
  String? _submittedCase;

  TextEditingController _input(String key) =>
      _inputs.putIfAbsent(key, () => TextEditingController());
  String _v(String key) => _input(key).text.trim();

  @override
  void initState() {
    super.initState();
    final suggested =
        WidgetsBinding.instance.platformDispatcher.locale.countryCode;
    if (suggested != null &&
        RegExp(r'^[A-Z]{2}$').hasMatch(suggested.toUpperCase())) {
      _countryCode = suggested.toUpperCase();
      _countryName = _countryCode;
    }
    _categories = (widget.loadCategories ?? _loadCategories)();
  }

  Future<List<Map<String, dynamic>>> _loadCategories() async {
    final db = WantokBackend.client;
    final categories = await db
        .from('service_categories')
        .select('id,name,slug')
        .eq('is_active', true)
        .order('name');
    final policies = await db
        .from('provider_onboarding_policies')
        .select('category_id,intake_status');
    final restricted = {
      for (final row in policies)
        if (row['intake_status'] == 'restricted') row['category_id'].toString(),
    };
    return (categories as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .where(
          (item) =>
              !restricted.contains(item['id'].toString()) &&
              !const {
                'health-medical',
                'financial-services',
                'public-services',
                'government-services',
                'community-services',
                'emergency-safety',
                'health-services',
              }.contains(item['slug']),
        )
        .toList();
  }

  @override
  void dispose() {
    for (final c in _inputs.values) {
      c.dispose();
    }
    super.dispose();
  }

  String get _slug => _category?['slug']?.toString() ?? '';
  bool get _vehicle =>
      _slug.contains('taxi') ||
      _slug.contains('vehicle') ||
      _slug.contains('transport') ||
      _slug.contains('delivery') ||
      _slug.contains('ride') ||
      _slug.contains('car-hire');
  bool get _food =>
      _slug.contains('food') ||
      _slug.contains('grocery') ||
      _slug.contains('restaurant') ||
      _slug.contains('catering');
  bool get _equipment =>
      _slug.contains('equipment') ||
      _slug.contains('machinery') ||
      _slug.contains('plant-hire');

  static const _vehicleFields = <String, String>{
    'vehicle_type': 'Vehicle type (car, van, truck, motorcycle, boat)',
    'vehicle_make': 'Vehicle make',
    'vehicle_model': 'Vehicle model',
    'vehicle_year': 'Manufacture year',
    'vehicle_plate': 'Registration / rego plate',
    'vehicle_registration_expiry': 'Vehicle registration expiry (YYYY-MM-DD)',
    'driver_licence_class': 'Driver licence class',
    'driver_licence_expiry': 'Driver licence expiry (YYYY-MM-DD)',
    'insurance_expiry': 'Vehicle insurance expiry (YYYY-MM-DD)',
  };
  static const _foodFields = <String, String>{
    'food_premises_type':
        'Food premises type (home, restaurant, commercial kitchen)',
    'food_handling_permit_expiry': 'Food-handling permit expiry (YYYY-MM-DD)',
  };
  static const _equipmentFields = <String, String>{
    'equipment_type': 'Machine / equipment type',
    'equipment_make': 'Manufacturer',
    'equipment_model': 'Model',
    'equipment_serial': 'Equipment serial / asset number',
    'equipment_inspection_expiry': 'Inspection expiry (YYYY-MM-DD)',
    'operator_qualification_expiry':
        'Operator qualification expiry (YYYY-MM-DD)',
  };
  static const _tradeFields = <String, String>{
    'trade_speciality': 'Trade or professional speciality (e.g. plumbing, IT)',
    'trade_licence_expiry': 'Trade licence expiry (YYYY-MM-DD)',
    'professional_registration_expiry': 'Registration expiry (YYYY-MM-DD)',
  };
  Map<String, String> get _fields => _vehicle
      ? _vehicleFields
      : _food
      ? _foodFields
      : _equipment
      ? _equipmentFields
      : _tradeFields;

  String? _required(String? input, {int min = 2, int max = 120}) {
    final text = input?.trim() ?? '';
    return text.length < min || text.length > max
        ? 'Please enter $min–$max characters'
        : null;
  }

  Widget _field(
    String name,
    String label, {
    bool required = false,
    int max = 120,
    bool email = false,
    TextInputType? inputType,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: TextFormField(
      key: ValueKey('vendor-field-$name'),
      controller: _input(name),
      maxLength: max,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        counterText: '',
        isDense: true,
      ),
      validator: (value) {
        if (required) {
          final minimum = name == 'summary'
              ? 10
              : name == 'phone'
              ? 7
              : name == 'address'
              ? 5
              : name == 'business_number'
              ? 3
              : name == 'tax4'
              ? 4
              : 2;
          final error = _required(value, min: minimum, max: max);
          if (error != null) {
            return error;
          }
        }
        if ((name == 'tax4' || name == 'identity4') &&
            (value ?? '').trim().isNotEmpty &&
            !RegExp(r'^[A-Za-z0-9]{4}$').hasMatch((value ?? '').trim())) {
          return 'Use exactly four letters or digits';
        }
        if (email &&
            !RegExp(r'^[^ @]+@[^ @]+[.][^ @]+$')
                .hasMatch((value ?? '').trim())) {
          return 'Enter a valid email';
        }
        return null;
      },
    ),
  );

  bool _validateStep() {
    final valid = _stepForms[_step].currentState?.validate() ?? false;
    if (_step == 0 && _category == null) {
      _message('Choose a service category.');
      return false;
    }
    return valid;
  }

  Future<void> _next() async {
    if (!_validateStep()) return;
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    if (!_consent) {
      _message('Confirm the declarations before submitting.');
      return;
    }
    if (_busy || _category == null) return;
    setState(() => _busy = true);
    try {
      final metadata = {
        for (final e in _fields.entries)
          if (_v(e.key).isNotEmpty) e.key: _v(e.key),
      };
      final payload = <String, dynamic>{
        'p_category_slug': _slug,
        'p_kind': _kind,
        'p_display_name': _v('name'),
        'p_country_code': _countryCode,
        'p_region': _v('region'),
        'p_locality': _v('locality'),
        'p_street_address': _v('address'),
        'p_email': _v('email'),
        'p_phone': _v('phone'),
        'p_identity_type': _identityType,
        'p_identity_last_four': _v('identity4').isEmpty
            ? null
            : _v('identity4'),
        'p_business_registration': _kind == 'business'
            ? _v('business_number')
            : null,
        'p_tax_reference_last_four': _kind == 'business' ? _v('tax4') : null,
        'p_summary': _v('summary'),
        'p_metadata': metadata,
      };
      final id = widget.submitForReview != null
          ? await widget.submitForReview!(payload)
          : (await WantokBackend.client.rpc(
              'submit_vendor_intake_case',
              params: payload,
            )).toString();
      if (mounted) setState(() => _submittedCase = id);
    } catch (error) {
      if (mounted) _message('Submission could not be completed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showMyCases() async {
    // Applicant read access is restricted to their own cases by database RLS.
    try {
      final user = WantokBackend.client.auth.currentUser;
      if (user == null) {
        _message('Sign in to view applications.');
        return;
      }
      final rows = await WantokBackend.client
          .from('vendor_intake_cases')
          .select(
            'id,display_name,status,submitted_at,service_categories(name)',
          )
          .eq('applicant_id', user.id)
          .order('submitted_at', ascending: false)
          .limit(50);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('My vendor applications'),
          content: SizedBox(
            width: 550,
            child: ListView(
              shrinkWrap: true,
              children: [
                if (rows.isEmpty)
                  const ListTile(
                    title: Text('No applications yet'),
                    subtitle: Text(
                      'Submit the form to receive a traceable case reference.',
                    ),
                  ),
                for (final row in rows)
                  ListTile(
                    leading: const Icon(Icons.assignment_outlined),
                    title: Text(
                      row['display_name']?.toString() ?? 'Application',
                    ),
                    subtitle: Text(
                      'Status: ${row['status']}'
                      '\nCase: ${row['id']}'
                      '\nSubmitted: ${row['submitted_at']}',
                    ),
                    isThreeLine: true,
                    trailing: row['status'] == 'needs_information'
                        ? IconButton(
                            tooltip: 'Reply to information request',
                            icon: const Icon(Icons.reply_outlined),
                            onPressed: () async {
                              try {
                                final sent = await sendVendorCaseReply(
                                  dialogContext,
                                  row['id'].toString(),
                                );
                                if (sent && dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                  _message(
                                    'Response submitted for staff review.',
                                  );
                                }
                              } catch (error) {
                                if (mounted) _message('Reply failed: $error');
                              }
                            },
                          )
                        : null,
                    onTap: () async {
                      final events = await WantokBackend.client
                          .from('vendor_intake_events')
                          .select('event_type,next_status,reason,recorded_at')
                          .eq('case_id', row['id'])
                          .order('recorded_at');
                      if (!dialogContext.mounted) return;
                      await showDialog<void>(
                        context: dialogContext,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Application status history'),
                          content: SizedBox(
                            width: 500,
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                for (final event in events)
                                  ListTile(
                                    title: Text(
                                      event['event_type']?.toString() ??
                                          'Update',
                                    ),
                                    subtitle: Text(
                                      '${event['recorded_at']}'
                                      '\n${event['reason'] ?? 'No additional message'}',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) _message('Cannot open applications: $error');
    }
  }

  void _message(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Become a Wantok vendor'),
      actions: [
        IconButton(
          tooltip: 'My evidence requirements (no uploads)',
          icon: const Icon(Icons.shield_outlined),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const VendorEvidenceInboxPage(),
            ),
          ),
        ),
        IconButton(
          tooltip: 'My application cases',
          icon: const Icon(Icons.assignment_turned_in_outlined),
          onPressed: _showMyCases,
        ),
        IconButton(
          tooltip: 'Earlier vendor applications',
          icon: const Icon(Icons.history),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ProviderApplicationPage(),
            ),
          ),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: _submittedCase != null ? _success() : _wizard(),
      ),
    ),
  );

  Widget _success() => ListView(
    padding: const EdgeInsets.all(25),
    children: [
      const Icon(
        Icons.mark_email_read_rounded,
        size: 62,
        color: WantokColors.primary,
      ),
      const SizedBox(height: 12),
      const Text(
        'Application received for review',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 10),
      SelectableText('Reference: $_submittedCase', textAlign: TextAlign.center),
      const SizedBox(height: 14),
      const Text(
        'You have NOT been verified or approved to operate. '
        'Operations will review your application and request the required '
        'identity, business, licence or insurance evidence using a secure process. '
        'Please do not email full ID documents or TIN numbers.',
      ),
      const SizedBox(height: 15),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Return to Wantok'),
      ),
    ],
  );

  Widget _wizard() => FutureBuilder<List<Map<String, dynamic>>>(
    future: _categories,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(
          child: Text('Cannot load available categories: ${snapshot.error}'),
        );
      }
      final cats = snapshot.data!;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF003F2D), Color(0xFF067C52)],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WANTOK PROVIDER ONBOARDING',
                  style: TextStyle(
                    color: WantokColors.gold,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Individual or Registered Business',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'A traceable application. Activation only after independent checks.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'We collect contact and service details now. '
            'Full NID, passport, licence and tax documents require a separate, '
            'secure verification process. Do not put those numbers in free text.',
            style: TextStyle(fontSize: 12, color: WantokColors.muted),
          ),
          const SizedBox(height: 12),
          Stepper(
            currentStep: _step,
            physics: const NeverScrollableScrollPhysics(),
            margin: EdgeInsets.zero,
            controlsBuilder: (context, details) => Wrap(
              spacing: 9,
              runSpacing: 8,
              children: [
                FilledButton(
                  key: const ValueKey('vendor-wizard-next'),
                  onPressed: _busy ? null : _next,
                  child: Text(
                    _busy
                        ? 'Submitting...'
                        : _step == 3
                        ? 'Submit application'
                        : 'Continue',
                  ),
                ),
                if (_step > 0)
                  OutlinedButton(
                    onPressed: _busy ? null : () => setState(() => _step--),
                    child: const Text('Back'),
                  ),
              ],
            ),
            onStepTapped: (index) {
              if (index < _step) setState(() => _step = index);
            },
            steps: [
              Step(
                title: const Text('Applicant & category'),
                isActive: _step >= 0,
                state: _step > 0 ? StepState.complete : StepState.indexed,
                content: _section(0, [
                  DropdownButtonFormField<String>(
                    key: const ValueKey('vendor-kind'),
                    initialValue: _kind,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'individual',
                        child: Text('Individual / sole provider'),
                      ),
                      DropdownMenuItem(
                        value: 'business',
                        child: Text('Registered business / company'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _kind = v ?? 'individual'),
                    decoration: const InputDecoration(labelText: 'Applying as'),
                  ),
                  const SizedBox(height: 13),
                  DropdownButtonFormField<String>(
                    key: const ValueKey('vendor-category'),
                    initialValue: _category?['slug']?.toString(),
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Service category',
                    ),
                    items: [
                      for (final cat in cats)
                        DropdownMenuItem(
                          value: cat['slug'].toString(),
                          child: Text(
                            cat['name'].toString(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(
                      () => _category = cats
                          .where((cat) => cat['slug'] == v)
                          .firstOrNull,
                    ),
                  ),
                  const SizedBox(height: 13),
                  _field(
                    'name',
                    _kind == 'business'
                        ? 'Registered business name'
                        : 'Your full legal name',
                    required: true,
                  ),
                  if (_kind == 'business') ...[
                    _field(
                      'business_number',
                      'Business / company registration number',
                      required: true,
                      max: 70,
                    ),
                    _field(
                      'tax4',
                      'Last 4 characters of business TIN / tax reference',
                      required: true,
                      max: 4,
                    ),
                  ],
                  _field(
                    'summary',
                    'Describe the work or service you plan to offer',
                    required: true,
                    max: 1200,
                  ),
                ]),
              ),
              Step(
                title: const Text('Contacts & location'),
                isActive: _step >= 1,
                content: _section(1, [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.public),
                      label: Text('Operating country: $_countryName'),
                      onPressed: () => showCountryPicker(
                        context: context,
                        showPhoneCode: false,
                        onSelect: (c) => setState(() {
                          _countryCode = c.countryCode;
                          _countryName = c.name;
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _field('region', 'State / Province / Region', required: true),
                  _field('locality', 'City / Town', required: true),
                  _field(
                    'address',
                    'Physical operating address',
                    required: true,
                    max: 240,
                  ),
                  _field(
                    'email',
                    'Contact email',
                    required: true,
                    max: 240,
                    email: true,
                    inputType: TextInputType.emailAddress,
                  ),
                  _field(
                    'phone',
                    'Phone (include country code)',
                    required: true,
                    max: 35,
                    inputType: TextInputType.phone,
                  ),
                  DropdownButtonFormField<String>(
                    key: const ValueKey('vendor-id-type'),
                    initialValue: _identityType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Identity document type',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'national_id',
                        child: Text('National ID / NID'),
                      ),
                      DropdownMenuItem(
                        value: 'passport',
                        child: Text('Passport'),
                      ),
                      DropdownMenuItem(
                        value: 'drivers_licence',
                        child: Text('Driver licence'),
                      ),
                      DropdownMenuItem(
                        value: 'other',
                        child: Text('Other recognised ID'),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _identityType = v ?? 'national_id'),
                  ),
                  const SizedBox(height: 12),
                  _field(
                    'identity4',
                    'Last 4 characters of ID (optional)',
                    max: 4,
                  ),
                ]),
              ),
              Step(
                title: const Text('Category-specific credentials'),
                isActive: _step >= 2,
                content: _section(2, [
                  Text(
                    'Requirements for ${_category?['name'] ?? 'the selected category'}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  for (final e in _fields.entries)
                    _field(
                      e.key,
                      e.value,
                      max: 120,
                      required:
                          (_vehicle &&
                              const {
                                'vehicle_type',
                                'vehicle_plate',
                                'driver_licence_class',
                                'driver_licence_expiry',
                                'vehicle_registration_expiry',
                              }.contains(e.key)) ||
                          (_equipment &&
                              const {
                                'equipment_type',
                                'equipment_serial',
                              }.contains(e.key)) ||
                          (_food && e.key == 'food_premises_type') ||
                          (!_vehicle &&
                              !_equipment &&
                              !_food &&
                              e.key == 'trade_speciality'),
                    ),
                  const Text(
                    'Numbers and expiry dates will be checked independently. '
                    'Entering them does not confirm a licence, permit, registration, '
                    'insurance or safety inspection is valid.',
                    style: TextStyle(fontSize: 12, color: WantokColors.muted),
                  ),
                ]),
              ),
              Step(
                title: const Text('Review & submit'),
                isActive: _step >= 3,
                content: _section(3, [
                  Text('Applicant: ${_v('name')} (${_kind.toUpperCase()})'),
                  Text('Category: ${_category?['name'] ?? '-'}'),
                  Text(
                    'Country: $_countryCode, ${_v('region')}, ${_v('locality')}',
                  ),
                  Text('Email: ${_v('email')} · Phone: ${_v('phone')}'),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    key: const ValueKey('vendor-intake-declaration'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'I confirm the information is accurate and '
                      'understand I am not authorised to trade, drive, take bookings '
                      'or receive payouts until the required checks are complete.',
                      style: TextStyle(fontSize: 13),
                    ),
                    value: _consent,
                    onChanged: (v) => setState(() => _consent = v ?? false),
                  ),
                  const Text(
                    'Application submissions and later staff review actions '
                    'are time-stamped and recorded for accountability.',
                    style: TextStyle(fontSize: 12, color: WantokColors.muted),
                  ),
                ]),
              ),
            ],
          ),
        ],
      );
    },
  );

  Widget _section(int index, List<Widget> children) => Form(
    key: _stepForms[index],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}
