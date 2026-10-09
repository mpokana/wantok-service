import 'package:flutter/material.dart';
import 'package:wantok_ui/wantok_ui.dart';

/// One customer identity: account preferences, payment preview, and
/// server-authorised vendor onboarding/workspace all start from Profile.
enum WantokProfileAction { settings, wallet, vendor }

class WantokProfileMenu extends StatelessWidget {
  const WantokProfileMenu({required this.onSelected, super.key});

  final ValueChanged<WantokProfileAction> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<WantokProfileAction>(
    key: const ValueKey('wantok-profile-menu'),
    tooltip: 'Account and profile',
    icon: const Icon(
      Icons.account_circle_outlined,
      color: WantokColors.primary,
    ),
    onSelected: onSelected,
    itemBuilder: (context) => const [
      PopupMenuItem(
        value: WantokProfileAction.settings,
        child: ListTile(
          dense: true,
          leading: Icon(Icons.settings_outlined),
          title: Text('My Settings'),
        ),
      ),
      PopupMenuItem(
        value: WantokProfileAction.wallet,
        child: ListTile(
          dense: true,
          leading: Icon(Icons.account_balance_wallet_outlined),
          title: Text('Wallet'),
        ),
      ),
      PopupMenuItem(
        value: WantokProfileAction.vendor,
        child: ListTile(
          dense: true,
          leading: Icon(Icons.storefront_outlined),
          title: Text('Vendor'),
        ),
      ),
    ],
  );
}
