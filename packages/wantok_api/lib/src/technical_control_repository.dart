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
      lastHealthAt: _dateTime(row['last_health_at']),
      accessLevelCode: row['access_level_code'] as String? ?? 'tech_auditor',
      permissionCodes:
          ((row['permission_codes'] as List<dynamic>?) ?? const <dynamic>[])
              .map((value) => value.toString())
              .toSet(),
    );
  }
}

class TechnicalAccessLevelOption {
  const TechnicalAccessLevelOption({
    required this.code,
    required this.name,
    required this.description,
    required this.rank,
  });

  final String code;
  final String name;
  final String? description;
  final int rank;

  factory TechnicalAccessLevelOption.fromMap(Map<String, dynamic> row) {
    return TechnicalAccessLevelOption(
      code: row['code'] as String,
      name: row['name'] as String,
      description: row['description'] as String?,
      rank: row['rank'] as int,
    );
  }
}

class TechnicalModuleStaff {
  const TechnicalModuleStaff({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.accessLevelCode,
    required this.accessLevelName,
    required this.accessRank,
    required this.grantedBy,
    required this.grantedByName,
    required this.grantedAt,
    required this.expiresAt,
    required this.notes,
  });

  final String userId;
  final String fullName;
  final String? email;
  final String accessLevelCode;
  final String accessLevelName;
  final int accessRank;
  final String? grantedBy;
  final String? grantedByName;
  final DateTime grantedAt;
  final DateTime? expiresAt;
  final String? notes;

  factory TechnicalModuleStaff.fromMap(Map<String, dynamic> row) {
    return TechnicalModuleStaff(
      userId: row['user_id'] as String,
      fullName: row['full_name'] as String? ?? 'Wantok user',
      email: row['email'] as String?,
      accessLevelCode: row['access_level_code'] as String,
      accessLevelName: row['access_level_name'] as String,
      accessRank: row['access_rank'] as int,
      grantedBy: row['granted_by'] as String?,
      grantedByName: row['granted_by_name'] as String?,
      grantedAt:
          _dateTime(row['granted_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      expiresAt: _dateTime(row['expires_at']),
      notes: row['notes'] as String?,
    );
  }
}

class TechnicalAccountCandidate {
  const TechnicalAccountCandidate({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.currentAccessLevelCode,
    required this.currentAccessLevelName,
    required this.isPlatformAdmin,
  });

  final String userId;
  final String fullName;
  final String? email;
  final String? currentAccessLevelCode;
  final String? currentAccessLevelName;
  final bool isPlatformAdmin;

  factory TechnicalAccountCandidate.fromMap(Map<String, dynamic> row) {
    return TechnicalAccountCandidate(
      userId: row['user_id'] as String,
      fullName: row['full_name'] as String? ?? 'Wantok user',
      email: row['email'] as String?,
      currentAccessLevelCode: row['current_access_level_code'] as String?,
      currentAccessLevelName: row['current_access_level_name'] as String?,
      isPlatformAdmin: row['is_platform_admin'] as bool? ?? false,
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
    return _maps(result)
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

  Future<List<TechnicalAccessLevelOption>> loadAssignableAccessLevels(
    String moduleKey,
  ) async {
    final result = await WantokBackend.client.rpc(
      'list_assignable_technical_access_levels',
      params: {'p_module_key': moduleKey},
    );
    return _maps(result)
        .map(TechnicalAccessLevelOption.fromMap)
        .toList(growable: false);
  }

  Future<List<TechnicalModuleStaff>> loadModuleStaff(String moduleKey) async {
    final result = await WantokBackend.client.rpc(
      'list_technical_module_staff',
      params: {'p_module_key': moduleKey},
    );
    return _maps(result)
        .map(TechnicalModuleStaff.fromMap)
        .toList(growable: false);
  }

  Future<List<TechnicalAccountCandidate>> searchTechnicalAccounts({
    required String moduleKey,
    required String query,
  }) async {
    final result = await WantokBackend.client.rpc(
      'search_technical_accounts',
      params: {'p_module_key': moduleKey, 'p_query': query},
    );
    return _maps(result)
        .map(TechnicalAccountCandidate.fromMap)
        .toList(growable: false);
  }

  Future<void> grantModuleAccess({
    required String userId,
    required String moduleKey,
    required String accessLevelCode,
    DateTime? expiresAt,
    String? notes,
  }) async {
    await WantokBackend.client.rpc(
      'grant_technical_module_access',
      params: {
        'p_user_id': userId,
        'p_module_key': moduleKey,
        'p_access_level_code': accessLevelCode,
        'p_expires_at': expiresAt?.toUtc().toIso8601String(),
        'p_notes': notes,
      },
    );
  }

  Future<bool> revokeModuleAccess({
    required String userId,
    required String moduleKey,
  }) async {
    final result = await WantokBackend.client.rpc(
      'revoke_technical_module_access',
      params: {'p_user_id': userId, 'p_module_key': moduleKey},
    );
    return result == true;
  }
}

List<Map<String, dynamic>> _maps(dynamic value) {
  if (value is! List<dynamic>) return const <Map<String, dynamic>>[];
  return value
      .map((row) => Map<String, dynamic>.from(row as Map))
      .toList(growable: false);
}

Map<String, dynamic> _singleMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is List<dynamic> && value.isNotEmpty) {
    return Map<String, dynamic>.from(value.first as Map);
  }
  throw StateError('Technical module response was empty.');
}

DateTime? _dateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
