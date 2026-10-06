import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wantok_api/wantok_api.dart';
import 'package:wantok_ui/wantok_ui.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({required this.profile, super.key});

  final AccountProfile profile;

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  static const _repository = AccountRepository();

  late String _profileVisibility;
  late String _reviewVisibility;
  late bool _savedPrivate;
  late bool _recommendations;
  late bool _profileSharing;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _profileVisibility = widget.profile.profileVisibility;
    _reviewVisibility = widget.profile.reviewVisibility;
    _savedPrivate = widget.profile.savedItemsPrivate;
    _recommendations = widget.profile.allowRecommendations;
    _profileSharing = widget.profile.allowProfileSharing;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _repository.updateAccountProfile(
        fullName: widget.profile.fullName,
        preferredName: widget.profile.preferredName,
        phone: widget.profile.phone,
        addressText: widget.profile.addressText,
        avatarUrl: widget.profile.avatarUrl,
        bio: widget.profile.bio,
        notifyBookingUpdates: widget.profile.notifyBookingUpdates,
        notifyMessages: widget.profile.notifyMessages,
        notifyPromotions: widget.profile.notifyPromotions,
        profileVisibility: _profileVisibility,
        reviewVisibility: _reviewVisibility,
        savedItemsPrivate: _savedPrivate,
        allowRecommendations: _recommendations,
        allowProfileSharing: _profileSharing,
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
      appBar: AppBar(title: const Text('Privacy & sharing')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const _IntroCard(
            icon: Icons.privacy_tip_outlined,
            title: 'You decide what is shared',
            body: 'Keep your personal account private, make it visible to signed-in Wantok users, or publish selected profile details.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _profileVisibility,
            decoration: const InputDecoration(
              labelText: 'Profile visibility',
              prefixIcon: Icon(Icons.person_search_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'private', child: Text('Private')),
              DropdownMenuItem(
                value: 'registered',
                child: Text('Signed-in Wantok users'),
              ),
              DropdownMenuItem(value: 'public', child: Text('Public')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _profileVisibility = value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _reviewVisibility,
            decoration: const InputDecoration(
              labelText: 'Default review visibility',
              prefixIcon: Icon(Icons.reviews_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'private', child: Text('Private')),
              DropdownMenuItem(
                value: 'registered',
                child: Text('Signed-in Wantok users'),
              ),
              DropdownMenuItem(value: 'public', child: Text('Public')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _reviewVisibility = value);
            },
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            value: _savedPrivate,
            onChanged: (value) => setState(() => _savedPrivate = value),
            title: const Text('Keep saved items private'),
            subtitle: const Text(
              'Saved services, providers, places and events are only visible to you.',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _recommendations,
            onChanged: (value) => setState(() => _recommendations = value),
            title: const Text('Personalised recommendations'),
            subtitle: const Text(
              'Use Wantok activity and saved items to improve suggestions.',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _profileSharing,
            onChanged: (value) => setState(() => _profileSharing = value),
            title: const Text('Allow profile sharing'),
            subtitle: const Text(
              'Permit share links for profile information allowed by your visibility setting.',
            ),
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
            label: Text(_saving ? 'Saving...' : 'Save privacy settings'),
          ),
        ],
      ),
    );
  }
}

class LinkedAccountsPage extends StatefulWidget {
  const LinkedAccountsPage({super.key});

  @override
  State<LinkedAccountsPage> createState() => _LinkedAccountsPageState();
}

class _LinkedAccountsPageState extends State<LinkedAccountsPage> {
  static const _repository = ClientExperienceRepository();
  String? _busyProvider;

  Future<void> _link(String name, OAuthProvider provider) async {
    setState(() => _busyProvider = name.toLowerCase());
    try {
      final opened = await _repository.linkIdentity(provider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              opened
                  ? 'Complete the $name sign-in to link this account.'
                  : 'Could not open $name sign-in.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _busyProvider = null);
    }
  }

  Future<void> _unlink(UserIdentity identity) async {
    if (_repository.linkedIdentities.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keep at least one sign-in method linked.'),
        ),
      );
      return;
    }

    setState(() => _busyProvider = identity.provider);
    try {
      await _repository.unlinkIdentity(identity);
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _busyProvider = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final identities = _repository.linkedIdentities;
    return Scaffold(
      appBar: AppBar(title: const Text('Linked accounts')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const _IntroCard(
            icon: Icons.link_rounded,
            title: 'One Wantok account',
            body: 'Link supported sign-in providers to the same Wantok account. Linking never creates a separate customer or vendor profile.',
          ),
          const SizedBox(height: 14),
          _IdentityTile(
            name: 'Google',
            icon: Icons.g_mobiledata_rounded,
            identity: _identityFor(identities, 'google'),
            busy: _busyProvider == 'google',
            onConnect: () => _link('Google', OAuthProvider.google),
            onDisconnect: _unlink,
          ),
          const SizedBox(height: 10),
          _IdentityTile(
            name: 'Facebook',
            icon: Icons.facebook_rounded,
            identity: _identityFor(identities, 'facebook'),
            busy: _busyProvider == 'facebook',
            onConnect: () => _link('Facebook', OAuthProvider.facebook),
            onDisconnect: _unlink,
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text(
                'Email & password',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                _identityFor(identities, 'email') != null
                    ? 'Connected'
                    : 'Managed by your Wantok sign-in',
              ),
              trailing: const Icon(
                Icons.check_circle,
                color: WantokColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SavedItemsPage extends StatefulWidget {
  const SavedItemsPage({super.key});

  @override
  State<SavedItemsPage> createState() => _SavedItemsPageState();
}

class _SavedItemsPageState extends State<SavedItemsPage> {
  static const _repository = ClientExperienceRepository();
  late Future<List<SavedClientItem>> _future;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _future = _repository.loadSavedItems();
  }

  Future<void> _refresh() async {
    final next = _repository.loadSavedItems();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {}
  }

  Future<void> _remove(SavedClientItem item) async {
    setState(() => _busyId = item.entityId);
    try {
      await _repository.setSavedItem(
        itemType: item.itemType,
        entityId: item.entityId,
        saved: false,
      );
      await _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<SavedClientItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ListState(
                icon: Icons.cloud_off_outlined,
                title: 'Could not load saved items',
                body: 'Check your connection and try again.',
                onRetry: _refresh,
              );
            }

            final items = snapshot.data ?? const <SavedClientItem>[];
            if (items.isEmpty) {
              return const _ListState(
                icon: Icons.bookmark_border_rounded,
                title: 'Nothing saved yet',
                body: 'Use the bookmark controls in Services to keep useful Wantok services close.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                final subtitle = item.subtitle == null
                    ? _savedTypeLabel(item.itemType)
                    : '${_savedTypeLabel(item.itemType)} • ${item.subtitle!}';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE4F5EC),
                      child: Icon(
                        _savedIcon(item.itemType),
                        color: WantokColors.primaryDark,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(subtitle),
                    trailing: IconButton(
                      tooltip: 'Remove from saved',
                      onPressed: _busyId == item.entityId
                          ? null
                          : () => _remove(item),
                      icon: _busyId == item.entityId
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.bookmark_remove_outlined),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class TrustedPeoplePage extends StatefulWidget {
  const TrustedPeoplePage({super.key});

  @override
  State<TrustedPeoplePage> createState() => _TrustedPeoplePageState();
}

class _TrustedPeoplePageState extends State<TrustedPeoplePage> {
  static const _repository = ClientExperienceRepository();
  late Future<List<TrustedPerson>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.loadTrustedPeople(includeInactive: true);
  }

  Future<void> _refresh() async {
    final next = _repository.loadTrustedPeople(includeInactive: true);
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {}
  }

  Future<void> _edit([TrustedPerson? existing]) async {
    final result = await showDialog<_TrustedDraft>(
      context: context,
      builder: (context) => _TrustedPersonDialog(person: existing),
    );
    if (result == null) return;

    try {
      if (existing == null) {
        await _repository.addTrustedPerson(
          displayName: result.displayName,
          relationship: result.relationship,
          phone: result.phone,
          email: result.email,
          notes: result.notes,
        );
      } else {
        await _repository.updateTrustedPerson(
          existing,
          displayName: result.displayName,
          relationship: result.relationship,
          phone: result.phone,
          email: result.email,
          notes: result.notes,
          isActive: result.isActive,
        );
      }
      await _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
    }
  }

  Future<void> _delete(TrustedPerson person) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${person.displayName}?'),
        content: const Text(
          'This removes the person from your trusted list. Existing bookings are not changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repository.deleteTrustedPerson(person.id);
      await _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_friendlyError(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trusted people'),
        actions: [
          IconButton(
            tooltip: 'Add trusted person',
            onPressed: _edit,
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
        ],
      ),
      body: FutureBuilder<List<TrustedPerson>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ListState(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load trusted people',
              body: 'Check your connection and try again.',
              onRetry: _refresh,
            );
          }

          final people = snapshot.data ?? const <TrustedPerson>[];
          if (people.isEmpty) {
            return _ListState(
              icon: Icons.group_add_outlined,
              title: 'No trusted people yet',
              body: 'Add family, relatives, staff or other people you may later book services for.',
              actionLabel: 'Add person',
              onRetry: _edit,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: people.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final person = people[index];
              final details = <String>[
                if (person.relationship?.trim().isNotEmpty == true)
                  person.relationship!,
                if (person.phone?.trim().isNotEmpty == true) person.phone!,
                if (!person.isActive) 'Inactive',
              ];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: person.isActive
                        ? const Color(0xFFE4F5EC)
                        : const Color(0xFFECECEC),
                    child: const Icon(
                      Icons.person_outline,
                      color: WantokColors.primaryDark,
                    ),
                  ),
                  title: Text(
                    person.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(details.join(' • ')),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _edit(person);
                      if (value == 'remove') _delete(person);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'remove', child: Text('Remove')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class MyReviewsPage extends StatefulWidget {
  const MyReviewsPage({super.key});

  @override
  State<MyReviewsPage> createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends State<MyReviewsPage> {
  static const _repository = ClientExperienceRepository();
  late Future<List<ClientReview>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.loadMyReviews();
  }

  Future<void> _refresh() async {
    final next = _repository.loadMyReviews();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My reviews')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<ClientReview>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ListState(
                icon: Icons.cloud_off_outlined,
                title: 'Could not load reviews',
                body: 'Check your connection and try again.',
                onRetry: _refresh,
              );
            }

            final reviews = snapshot.data ?? const <ClientReview>[];
            if (reviews.isEmpty) {
              return const _ListState(
                icon: Icons.rate_review_outlined,
                title: 'No reviews yet',
                body: 'Completed eligible services will offer a review action from Track.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reviews.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final review = reviews[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                review.providerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Text(
                              List.filled(review.rating, '★').join(),
                              style: const TextStyle(color: Color(0xFFE6A100)),
                            ),
                          ],
                        ),
                        if (review.title?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 7),
                          Text(
                            review.title!,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                        if (review.comment?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 5),
                          Text(review.comment!),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Visibility: ${review.visibility.replaceAll('_', ' ')}',
                          style: const TextStyle(
                            color: WantokColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _IdentityTile extends StatelessWidget {
  const _IdentityTile({
    required this.name,
    required this.icon,
    required this.identity,
    required this.busy,
    required this.onConnect,
    required this.onDisconnect,
  });

  final String name;
  final IconData icon;
  final UserIdentity? identity;
  final bool busy;
  final VoidCallback onConnect;
  final Future<void> Function(UserIdentity identity) onDisconnect;

  @override
  Widget build(BuildContext context) {
    final connected = identity != null;
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(connected ? 'Connected' : 'Not connected'),
        trailing: busy
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : connected
            ? OutlinedButton(
                onPressed: () => onDisconnect(identity!),
                child: const Text('Disconnect'),
              )
            : FilledButton(onPressed: onConnect, child: const Text('Connect')),
      ),
    );
  }
}

class _TrustedPersonDialog extends StatefulWidget {
  const _TrustedPersonDialog({this.person});

  final TrustedPerson? person;

  @override
  State<_TrustedPersonDialog> createState() => _TrustedPersonDialogState();
}

class _TrustedPersonDialogState extends State<_TrustedPersonDialog> {
  late final TextEditingController _name;
  late final TextEditingController _relationship;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _notes;
  late bool _active;

  @override
  void initState() {
    super.initState();
    final person = widget.person;
    _name = TextEditingController(text: person?.displayName ?? '');
    _relationship = TextEditingController(text: person?.relationship ?? '');
    _phone = TextEditingController(text: person?.phone ?? '');
    _email = TextEditingController(text: person?.email ?? '');
    _notes = TextEditingController(text: person?.notes ?? '');
    _active = person?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _relationship.dispose();
    _phone.dispose();
    _email.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    Navigator.of(context).pop(
      _TrustedDraft(
        displayName: _name.text.trim(),
        relationship: _emptyToNull(_relationship.text),
        phone: _emptyToNull(_phone.text),
        email: _emptyToNull(_email.text),
        notes: _emptyToNull(_notes.text),
        isActive: _active,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.person == null ? 'Add trusted person' : 'Edit person'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _relationship,
              decoration: const InputDecoration(
                labelText: 'Relationship',
                hintText: 'Parent, spouse, sibling, employee...',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            if (widget.person != null)
              SwitchListTile(
                value: _active,
                onChanged: (value) => setState(() => _active = value),
                title: const Text('Active'),
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

class _TrustedDraft {
  const _TrustedDraft({
    required this.displayName,
    required this.relationship,
    required this.phone,
    required this.email,
    required this.notes,
    required this.isActive,
  });

  final String displayName;
  final String? relationship;
  final String? phone;
  final String? email;
  final String? notes;
  final bool isActive;
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF4FAF7),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFE0F3E8),
              child: Icon(icon, color: WantokColors.primaryDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(
                      color: WantokColors.muted,
                      height: 1.35,
                    ),
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

class _ListState extends StatelessWidget {
  const _ListState({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 70),
        Icon(icon, size: 58, color: WantokColors.primary),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 7),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(color: WantokColors.muted),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(
              onPressed: onRetry,
              child: Text(actionLabel ?? 'Retry'),
            ),
          ),
        ],
      ],
    );
  }
}

UserIdentity? _identityFor(List<UserIdentity> identities, String provider) {
  for (final identity in identities) {
    if (identity.provider == provider) return identity;
  }
  return null;
}

String _savedTypeLabel(String type) => switch (type) {
  'provider' => 'Provider',
  'service' => 'Service',
  'resource' => 'Place or resource',
  'event' => 'Event',
  'category' => 'Service category',
  _ => 'Saved item',
};

IconData _savedIcon(String type) => switch (type) {
  'provider' => Icons.storefront_outlined,
  'service' => Icons.miscellaneous_services_outlined,
  'resource' => Icons.place_outlined,
  'event' => Icons.event_outlined,
  'category' => Icons.apps_outlined,
  _ => Icons.bookmark_outline,
};

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _friendlyError(Object error) {
  return error
      .toString()
      .replaceFirst('StateError: ', '')
      .replaceFirst('Invalid argument(s): ', '');
}
