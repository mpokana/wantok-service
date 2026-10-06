import 'wantok_backend.dart';

class TechnicalModuleAccess {
  const TechnicalModuleAccess({
    required this.moduleKey,
    required this.name,
    required this.description,
    required this.groupCode,
    required this.sortOrder,
    required this.isEnabled,
    required this.maintenanceMode,
    required this.version,
    required this.healthStatus,
    required this.lastHealthAt,
    required this.accessLevelCode,
    required this.permissionCodes,
  });

  final String moduleKey;
  final String name;
  final String? description;
  final String groupCode;
  final int sortOrder;
  final bool isEnabled;
  final bool maintenanceMode;
  final String? version;
  final String healthStatus;
  final DateTime? lastHealthAt;
  final String accessLevelCode;
  final Set<String> permissionCodes;

  bool hasPermission(String code) => permissionCodes.contains(code);

  factory TechnicalModuleAccess.fromMap(Map<String, dynamic> row) {
    return TechnicalModuleAccess(
      moduleKey: row['module_key'] as String,
      name: row['name'] as String,
      description: row['description'] as String?,
      groupCode: row['group_code'] as String,
      sortOrder: row['sort_order'] as int? ?? 0,
      isEnabled: row['is_enabled'] as bool? ?? false,
      maintenanceMode: row['maintenance_mode'] as bool? ?? false,
      version: row['version'] as String?,
      healthStatus: row['health_status'] as String? ?? 'unknown',
      lastHealthAt: DateTime.tryParse(row['last_health_at']?.toString() ?? ''),
      accessLevelCode: row['access_level_code'] as String? ?? 'tech_auditor',
      permissionCodes:
          ((row['permission_codes'] as List<dynamic>?) ?? const <dynamic>[])
              .map((value) => value.toString())
              .toSet(),
    );
  }
}

class TechnicalControlRepository {
  const TechnicalControlRepository();

  Future<bool> canAccessConsole() async {
    final result = await WantokBackend.client.rpc(
      'can_access_technical_console',
    );
    return result == true;
  }

  Future<List<TechnicalModuleAccess>> loadModules() async {
    final result = await WantokBackend.client.rpc('list_my_technical_modules');
    return (result as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(TechnicalModuleAccess.fromMap)
        .toList(growable: false);
  }

  Future<TechnicalModuleAccess> setModuleState({
    required String moduleKey,
    bool? enabled,
    bool? maintenanceMode,
  }) async {
    final result = await WantokBackend.client.rpc(
      'set_technical_module_state',
      params: {
        'p_module_key': moduleKey,
        'p_enabled': enabled,
        'p_maintenance_mode': maintenanceMode,
      },
    );

    final row = _singleMap(result);
    final refreshed = await loadModules();
    return refreshed.firstWhere(
      (module) => module.moduleKey == row['module_key'],
    );
  }
}

Map<String, dynamic> _singleMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is List<dynamic> && value.isNotEmpty) {
    return Map<String, dynamic>.from(value.first as Map);
  }
  throw StateError('Technical module response was empty.');
}
