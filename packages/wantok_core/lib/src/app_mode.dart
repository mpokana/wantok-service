enum AppMode { client, vendor }

extension AppModeLabel on AppMode {
  String get label => switch (this) {
    AppMode.client => 'Client',
    AppMode.vendor => 'Vendor',
  };
}
