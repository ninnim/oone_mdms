class Site {
  final int? id;
  final String name;
  final String description;
  final int parentId;
  final bool active;
  final List<Site>? subSites;

  const Site({
    this.id,
    required this.name,
    required this.description,
    required this.parentId,
    required this.active,
    this.subSites,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['Id'],
      name: json['Name'] ?? '',
      description: json['Description'] ?? '',
      parentId: json['ParentId'] ?? 0,
      active: json['Active'] ?? true,
      subSites: json['SubSites'] != null
          ? (json['SubSites'] as List)
                .map((subSite) => Site.fromJson(subSite))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Name': name,
      'Description': description,
      'ParentId': parentId,
      'Active': active,
      if (subSites != null)
        'SubSites': subSites!.map((site) => site.toJson()).toList(),
    };
  }

  Site copyWith({
    int? id,
    String? name,
    String? description,
    int? parentId,
    bool? active,
    List<Site>? subSites,
  }) {
    return Site(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      parentId: parentId ?? this.parentId,
      active: active ?? this.active,
      subSites: subSites ?? this.subSites,
    );
  }

  // Helper getters
  bool get isMainSite => parentId == 0;
  bool get isSubSite => parentId != 0;
  int get subSiteCount => subSites?.length ?? 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Site && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Site{id: $id, name: $name, description: $description, parentId: $parentId, active: $active}';
  }
}

// Response models for API
class SiteResponse {
  final List<Map<String, dynamic>> sites;

  const SiteResponse({required this.sites});

  factory SiteResponse.fromJson(Map<String, dynamic> json) {
    return SiteResponse(
      sites: List<Map<String, dynamic>>.from(json['Site'] ?? []),
    );
  }
}

class SiteListResponse {
  final List<Map<String, dynamic>> sites;
  final Map<String, dynamic>? paging;

  const SiteListResponse({required this.sites, this.paging});

  factory SiteListResponse.fromJson(Map<String, dynamic> json) {
    return SiteListResponse(
      sites: List<Map<String, dynamic>>.from(json['Site'] ?? []),
      paging: json['Paging'],
    );
  }
}
