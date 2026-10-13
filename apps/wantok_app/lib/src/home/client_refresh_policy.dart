import 'package:flutter/material.dart';

/// Shared Client/Vendor refresh presentation rule.
///
/// A pull gesture on a scrollable read-only listing is the primary refresh
/// affordance on phones/tablets. Wide desktop web retains explicit buttons.
/// This does not add refresh semantics to forms, payments, or write actions.
abstract final class ClientRefreshPolicy {
  static const double desktopMinWidth = 1200;

  static bool showDesktopButton(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopMinWidth;
}
