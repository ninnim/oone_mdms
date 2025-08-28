import 'tenant.dart';

class UserModule {
  final int moduleId;
  final String module;
  final String moduleCode;
  final bool isSuperUser;
  final String userId;

  UserModule({
    required this.moduleId,
    required this.module,
    required this.moduleCode,
    required this.isSuperUser,
    required this.userId,
  });

  factory UserModule.fromJson(Map<String, dynamic> json) {
    return UserModule(
      moduleId: json['moduleId'] ?? 0,
      module: json['module'] ?? '',
      moduleCode: json['moduleCode'] ?? '',
      isSuperUser: json['isSuperUser'] ?? false,
      userId: json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moduleId': moduleId,
      'module': module,
      'moduleCode': moduleCode,
      'isSuperUser': isSuperUser,
      'userId': userId,
    };
  }
}

class CurrentUserResponse {
  final bool hasAccessibleTenant;
  final bool hasAccessibleModule;
  final String tenantId;
  final Tenant currentTenant;
  final UserModule userModule;

  CurrentUserResponse({
    required this.hasAccessibleTenant,
    required this.hasAccessibleModule,
    required this.tenantId,
    required this.currentTenant,
    required this.userModule,
  });

  factory CurrentUserResponse.fromJson(Map<String, dynamic> json) {
    return CurrentUserResponse(
      hasAccessibleTenant: json['hasAccessibleTenant'] ?? false,
      hasAccessibleModule: json['hasAccessibleModule'] ?? false,
      tenantId: json['tenantId'] ?? '',
      currentTenant: Tenant.fromJson(json['currentTenant'] ?? {}),
      userModule: UserModule.fromJson(json['userModule'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasAccessibleTenant': hasAccessibleTenant,
      'hasAccessibleModule': hasAccessibleModule,
      'tenantId': tenantId,
      'currentTenant': currentTenant.toJson(),
      'userModule': userModule.toJson(),
    };
  }
}
