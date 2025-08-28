class Tenant {
  final String tenantId;
  final String tenant;
  final String tenantCode;
  final bool isSuperUser;
  final String status;
  final String lastAccessDate;
  final String type;
  final bool verified;
  final List<dynamic> attributes;
  final String userId;

  Tenant({
    required this.tenantId,
    required this.tenant,
    required this.tenantCode,
    required this.isSuperUser,
    required this.status,
    required this.lastAccessDate,
    required this.type,
    required this.verified,
    required this.attributes,
    required this.userId,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      tenantId: json['tenantId'] ?? '',
      tenant: json['tenant'] ?? '',
      tenantCode: json['tenantCode'] ?? '',
      isSuperUser: json['isSuperUser'] ?? false,
      status: json['status'] ?? '',
      lastAccessDate: json['lastAccessDate'] ?? '',
      type: json['type'] ?? '',
      verified: json['verified'] ?? false,
      attributes: json['attributes'] ?? [],
      userId: json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenantId': tenantId,
      'tenant': tenant,
      'tenantCode': tenantCode,
      'isSuperUser': isSuperUser,
      'status': status,
      'lastAccessDate': lastAccessDate,
      'type': type,
      'verified': verified,
      'attributes': attributes,
      'userId': userId,
    };
  }
}
