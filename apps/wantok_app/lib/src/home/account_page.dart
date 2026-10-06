import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

import '../vendor/provider_application_page.dart';
import 'client_account_tools.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({required this.roles, required this.onSignOut, super.key});

  final Set<String> roles;
  final Future<void> Function() onSignOut;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  static const _repository = AccountRepository();
  static const _experience = ClientExperienceRepository();
  late Future<_AccountData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AccountData> _load() async {
    final profile = await _repository.loadAccountProfile();
    final provider = await _repository.loadProviderProfile();
    String? avatarDisplayUrl;
    try {
      avatarDisplayUrl = await _experience.resolveMediaReference(
        profile.avatarUrl,
      );
    } catch (_) {
      avatarDisplayUrl = null;
    }
    return _AccountData(
      profile: profile,
      provider: provider,
      avatarDisplayUrl: avatarDisplayUrl,
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {
      // The FutureBuilder presents the retryable error state.
    }
  }

  Future<void> _editPersonal(AccountProfile profile) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => _EditPersonalProfilePage(profile: profile),
      ),
    );
    if (changed == true && mounted) await _refresh();
  }

  Future<void> _editProvider(ProviderAccountProfile profile) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => _EditProviderProfilePage(profile: profile),
      ),
    );
    if (changed == true && mounted) await _refresh();
  }

  Future<void> _changePassword() async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => const _ChangePasswordDialog(),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
    }
  }

  Future<void> _openPrivacy(AccountProfile profile) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => PrivacySettingsPage(profile: profile),
      ),
    );
    if (changed == true && mounted) await _refresh();
  }

  void _openTool(Widget page) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    final sortedRoles = widget.roles.toList()..sort();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<_AccountData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.error_outline,
                      color: WantokColors.coral,
                    ),
                    title: const Text('Could not load your account'),
                    subtitle: const Text(
                      'Check your connection and try again.',
                    ),
                    trailing: IconButton(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                ),
              ],
            );
          }

          final data = snapshot.data!;
          final profile = data.profile;
          final provider = data.provider;

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 36),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: const Color(0xFFE2F3E9),
                        backgroundImage: data.avatarDisplayUrl == null
                            ? null
                            : NetworkImage(data.avatarDisplayUrl!),
                        child: data.avatarDisplayUrl == null
                            ? Text(
                                _initials(profile.displayName),
                                style: const TextStyle(
                                  color: WantokColors.primaryDark,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.displayName,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _repository.email ?? 'Wantok account',
                              style: const TextStyle(color: WantokColors.muted),
                            ),
                            if (sortedRoles.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: sortedRoles
                                    .map(
                                      (role) => Chip(
                                        visualDensity: VisualDensity.compact,
                                        label: Text(_roleLabel(role)),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Personal details',
                icon: Icons.badge_outlined,
                onAction: () => _editPersonal(profile),
                children: [
                  _DetailRow(label: 'Full name', value: profile.fullName),
                  _DetailRow(
                    label: 'Preferred name',
                    value: _valueOrDash(profile.preferredName),
                  ),
                  _DetailRow(
                    label: 'Phone',
                    value: _valueOrDash(profile.phone),
                  ),
                  _DetailRow(
                    label: 'Address',
                    value: _valueOrDash(profile.addressText),
                  ),
                  _DetailRow(label: 'Bio', value: _valueOrDash(profile.bio)),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Notifications',
                icon: Icons.notifications_outlined,
                onAction: () => _editPersonal(profile),
                children: [
                  _PreferenceRow(
                    label: 'Booking updates',
                    enabled: profile.notifyBookingUpdates,
                  ),
                  _PreferenceRow(
                    label: 'Messages',
                    enabled: profile.notifyMessages,
                  ),
                  _PreferenceRow(
                    label: 'Promotions',
                    enabled: profile.notifyPromotions,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Your Wantok',
                icon: Icons.auto_awesome_outlined,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy & sharing'),
                    subtitle: Text(
                      'Profile: ${profile.profileVisibility} • Reviews: ${profile.reviewVisibility}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openPrivacy(profile),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.link_rounded),
                    title: const Text('Linked accounts'),
                    subtitle: const Text(
                      'Google, Facebook and sign-in methods',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openTool(const LinkedAccountsPage()),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.bookmark_outline_rounded),
                    title: const Text('Saved'),
                    subtitle: const Text(
                      'Services, providers, places and events',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openTool(const SavedItemsPage()),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.group_outlined),
                    title: const Text('Trusted people'),
                    subtitle: const Text(
                      'Family, relatives or staff you may book for',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openTool(const TrustedPeoplePage()),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.rate_review_outlined),
                    title: const Text('My reviews'),
                    subtitle: const Text(
                      'Ratings and feedback you have shared',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openTool(const MyReviewsPage()),
                  ),
                ],
              ),
              if (provider != null) ...[
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Business / vendor profile',
                  icon: Icons.storefront_outlined,
                  onAction: () => _editProvider(provider),
                  children: [
                    _DetailRow(
                      label: 'Display name',
                      value: provider.displayName,
                    ),
                    _DetailRow(
                      label: 'Provider type',
                      value: _providerTypeLabel(provider.providerType),
                    ),
                    _DetailRow(
                      label: 'Verification',
                      value: provider.verificationStatus
                          .replaceAll('_', ' ')
                          .toUpperCase(),
                    ),
                    _DetailRow(
                      label: 'Status',
                      value: provider.isActive ? 'ACTIVE' : 'INACTIVE',
                    ),
                    _DetailRow(
                      label: 'Base address',
                      value: _valueOrDash(provider.baseAddress),
                    ),
                    _DetailRow(
                      label: 'Service radius',
                      value: provider.serviceRadiusKm == null
                          ? '—'
                          : '${provider.serviceRadiusKm!.toStringAsFixed(0)} km',
                    ),
                    if (provider.bio?.trim().isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          provider.bio!,
                          style: const TextStyle(
                            color: WantokColors.muted,
                            height: 1.4,
                          ),
                        ),
                      ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Business / vendor profile',
                  icon: Icons.storefront_outlined,
                  children: [
                    const Text(
                      'Use the same Wantok account for a business or provider profile. '
                      'Provider capabilities remain subject to verification and approval.',
                      style: TextStyle(color: WantokColors.muted, height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _openTool(const ProviderApplicationPage()),
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        label: const Text('Apply for vendor profile'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Security',
                icon: Icons.shield_outlined,
                children: [
                  _DetailRow(label: 'Email', value: _repository.email ?? '—'),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _changePassword,
                      icon: const Icon(Icons.password_outlined),
                      label: const Text('Change password'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: widget.onSignOut,
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EditPersonalProfilePage extends StatefulWidget {
  const _EditPersonalProfilePage({required this.profile});
  final AccountProfile profile;

  @override
  State<_EditPersonalProfilePage> createState() =>
      _EditPersonalProfilePageState();
}

class _EditPersonalProfilePageState extends State<_EditPersonalProfilePage> {
  static const _repository = AccountRepository();
  static const _experience = ClientExperienceRepository();

  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _fullName;
  late final TextEditingController _preferredName;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _bio;
  late String _avatarReference;
  String? _avatarPreviewUrl;
  XFile? _pendingAvatar;
  Uint8List? _pendingAvatarBytes;
  bool _pickingAvatar = false;
  late bool _bookingUpdates;
  late bool _messages;
  late bool _promotions;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fullName = TextEditingController(text: widget.profile.fullName);
    _preferredName = TextEditingController(
      text: widget.profile.preferredName ?? '',
    );
    _phone = TextEditingController(text: widget.profile.phone ?? '');
    _address = TextEditingController(text: widget.profile.addressText ?? '');
    _bio = TextEditingController(text: widget.profile.bio ?? '');
    _avatarReference = widget.profile.avatarUrl ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveAvatarPreview();
    });
    _bookingUpdates = widget.profile.notifyBookingUpdates;
    _messages = widget.profile.notifyMessages;
    _promotions = widget.profile.notifyPromotions;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _preferredName.dispose();
    _phone.dispose();
    _address.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _resolveAvatarPreview() async {
    if (_avatarReference.trim().isEmpty) {
      if (mounted) setState(() => _avatarPreviewUrl = null);
      return;
    }
    try {
      final url = await _experience.resolveMediaReference(_avatarReference);
      if (mounted) setState(() => _avatarPreviewUrl = url);
    } catch (_) {
      if (mounted) setState(() => _avatarPreviewUrl = null);
    }
  }

  Future<void> _pickAvatar() async {
    if (_pickingAvatar || _saving) return;
    setState(() => _pickingAvatar = true);
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 88,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pendingAvatar = file;
        _pendingAvatarBytes = bytes;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _pickingAvatar = false);
    }
  }

  void _removeAvatar() {
    setState(() {
      _pendingAvatar = null;
      _pendingAvatarBytes = null;
      _avatarReference = '';
      _avatarPreviewUrl = null;
    });
  }

  Future<void> _save() async {
    if (_fullName.text.trim().isEmpty || _saving) return;
    setState(() => _saving = true);

    final previousAvatar = widget.profile.avatarUrl;
    String? newlyUploaded;
    var avatarReference = _avatarReference;

    try {
      if (_pendingAvatar != null && _pendingAvatarBytes != null) {
        newlyUploaded = await _experience.uploadAvatar(
          ClientMediaUpload(
            bytes: _pendingAvatarBytes!,
            fileName: _pendingAvatar!.name,
            mimeType: _pendingAvatar!.mimeType,
          ),
        );
        avatarReference = newlyUploaded;
      }

      await _repository.updateAccountProfile(
        fullName: _fullName.text.trim(),
        preferredName: _emptyToNull(_preferredName.text),
        phone: _emptyToNull(_phone.text),
        addressText: _emptyToNull(_address.text),
        avatarUrl: avatarReference,
        bio: _bio.text.trim(),
        notifyBookingUpdates: _bookingUpdates,
        notifyMessages: _messages,
        notifyPromotions: _promotions,
      );

      if (previousAvatar != null &&
          previousAvatar.trim().isNotEmpty &&
          previousAvatar != avatarReference) {
        try {
          await _experience.removeMediaReferences([previousAvatar]);
        } catch (_) {
          // Profile update succeeded; stale media cleanup is best-effort.
        }
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (newlyUploaded != null) {
        try {
          await _experience.removeMediaReferences([newlyUploaded]);
        } catch (_) {
          // Preserve the primary save error.
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit account')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            controller: _fullName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _preferredName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Preferred name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone',
              prefixIcon: Icon(Icons.phone_outlined),
              hintText: '+675 ...',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Address',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFFF7FAF8),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: const Color(0xFFE2F3E9),
                    backgroundImage: _pendingAvatarBytes != null
                        ? MemoryImage(_pendingAvatarBytes!)
                        : _avatarPreviewUrl == null
                        ? null
                        : NetworkImage(_avatarPreviewUrl!) as ImageProvider,
                    child:
                        _pendingAvatarBytes == null && _avatarPreviewUrl == null
                        ? Text(
                            _initials(
                              _preferredName.text.trim().isEmpty
                                  ? _fullName.text
                                  : _preferredName.text,
                            ),
                            style: const TextStyle(
                              color: WantokColors.primaryDark,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profile photo',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'JPG, PNG or WebP • maximum 5 MB',
                          style: TextStyle(
                            color: WantokColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickingAvatar || _saving
                                  ? null
                                  : _pickAvatar,
                              icon: _pickingAvatar
                                  ? const SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.photo_library_outlined),
                              label: Text(
                                _pickingAvatar ? 'Opening...' : 'Choose photo',
                              ),
                            ),
                            if (_pendingAvatarBytes != null ||
                                _avatarReference.trim().isNotEmpty)
                              TextButton.icon(
                                onPressed: _saving ? null : _removeAvatar,
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Remove'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bio,
            minLines: 3,
            maxLines: 5,
            maxLength: 1200,
            decoration: const InputDecoration(
              labelText: 'About you',
              prefixIcon: Icon(Icons.notes_outlined),
              hintText: 'A short introduction for your Wantok profile.',
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Notifications',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _bookingUpdates,
            onChanged: (value) => setState(() => _bookingUpdates = value),
            title: const Text('Booking updates'),
            subtitle: const Text('Status changes, quotes and job updates.'),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _messages,
            onChanged: (value) => setState(() => _messages = value),
            title: const Text('Messages'),
            subtitle: const Text('Customer and provider conversation updates.'),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _promotions,
            onChanged: (value) => setState(() => _promotions = value),
            title: const Text('Promotions'),
            subtitle: const Text('Optional offers and promotional notices.'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Saving...' : 'Save changes'),
          ),
        ],
      ),
    );
  }
}

class _EditProviderProfilePage extends StatefulWidget {
  const _EditProviderProfilePage({required this.profile});
  final ProviderAccountProfile profile;

  @override
  State<_EditProviderProfilePage> createState() =>
      _EditProviderProfilePageState();
}

class _EditProviderProfilePageState extends State<_EditProviderProfilePage> {
  static const _repository = AccountRepository();

  late final TextEditingController _displayName;
  late final TextEditingController _bio;
  late final TextEditingController _baseAddress;
  late final TextEditingController _radius;
  late String _providerType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _displayName = TextEditingController(text: widget.profile.displayName);
    _bio = TextEditingController(text: widget.profile.bio ?? '');
    _baseAddress = TextEditingController(
      text: widget.profile.baseAddress ?? '',
    );
    _radius = TextEditingController(
      text: widget.profile.serviceRadiusKm?.toStringAsFixed(0) ?? '',
    );
    _providerType = widget.profile.providerType;
  }

  @override
  void dispose() {
    _displayName.dispose();
    _bio.dispose();
    _baseAddress.dispose();
    _radius.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_displayName.text.trim().isEmpty || _saving) return;
    final radiusText = _radius.text.trim();
    final radius = radiusText.isEmpty ? null : double.tryParse(radiusText);
    if (radiusText.isNotEmpty && radius == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid service radius.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _repository.updateProviderProfile(
        displayName: _displayName.text.trim(),
        providerType: _providerType,
        bio: _emptyToNull(_bio.text),
        baseAddress: _emptyToNull(_baseAddress.text),
        serviceRadiusKm: radius,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit provider profile')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            controller: _displayName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Provider display name',
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _providerType,
            decoration: const InputDecoration(
              labelText: 'Provider type',
              prefixIcon: Icon(Icons.business_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'individual', child: Text('Individual')),
              DropdownMenuItem(value: 'business', child: Text('Business')),
              DropdownMenuItem(
                value: 'organisation',
                child: Text('Organisation'),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _providerType = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bio,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'About this provider',
              prefixIcon: Icon(Icons.description_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _baseAddress,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Base address',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _radius,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Service radius (km)',
              prefixIcon: Icon(Icons.radar_outlined),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            color: Color(0xFFF4F7F5),
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Verification and activation are controlled by authorised administrators and cannot be changed here.',
                style: TextStyle(color: WantokColors.muted),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Saving...' : 'Save provider profile'),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  static const _repository = AccountRepository();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final password = _password.text;
    if (password.length < 8) {
      setState(() => _error = 'Use at least 8 characters.');
      return;
    }
    if (password != _confirm.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repository.updatePassword(password);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'New password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirm,
              obscureText: _obscure,
              onSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Updating...' : 'Update password'),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.onAction,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: WantokColors.primaryDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (onAction != null)
                  TextButton(onPressed: onAction, child: const Text('Edit')),
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(color: WantokColors.muted),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Icon(
            enabled ? Icons.check_circle : Icons.remove_circle_outline,
            color: enabled ? WantokColors.primary : WantokColors.muted,
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            enabled ? 'On' : 'Off',
            style: TextStyle(
              color: enabled ? WantokColors.primaryDark : WantokColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountData {
  const _AccountData({
    required this.profile,
    required this.provider,
    required this.avatarDisplayUrl,
  });

  final AccountProfile profile;
  final ProviderAccountProfile? provider;
  final String? avatarDisplayUrl;
}

String _valueOrDash(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? '—' : trimmed;
}

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'W';
  if (parts.length == 1) {
    return parts.first
        .substring(0, parts.first.length > 1 ? 2 : 1)
        .toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _roleLabel(String role) {
  return switch (role) {
    'customer' => 'Customer',
    'provider' => 'Provider',
    'driver' => 'Driver',
    'admin' => 'Administrator',
    'operations' => 'Operations',
    'tech_platform_admin' => 'Technical Platform Administrator',
    'tech_admin' => 'Technical Administrator',
    'tech_module_admin' => 'Module Administrator',
    'tech_support' => 'Technical Support',
    'tech_auditor' => 'Technical Auditor',
    _ => role.replaceAll('_', ' '),
  };
}

String _providerTypeLabel(String value) {
  return switch (value) {
    'business' => 'Business',
    'organisation' => 'Organisation',
    _ => 'Individual',
  };
}

String _friendlyError(Object error) {
  return error
      .toString()
      .replaceFirst('StateError: ', '')
      .replaceFirst('Invalid argument(s): ', '');
}
