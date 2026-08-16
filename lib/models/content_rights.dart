enum ContentRightsType {
  owned,
  licensed,
  publicDomain,
  linkedOnly,
  permissionRequired,
  unknown,
}

ContentRightsType rightsTypeFromString(String value) {
  switch (value) {
    case 'owned':
      return ContentRightsType.owned;
    case 'licensed':
      return ContentRightsType.licensed;
    case 'public_domain':
      return ContentRightsType.publicDomain;
    case 'linked_only':
      return ContentRightsType.linkedOnly;
    case 'permission_required':
      return ContentRightsType.permissionRequired;
    case 'unknown':
    default:
      return ContentRightsType.unknown;
  }
}

/// Explicit rights metadata for a piece of content, so the content library
/// can state what may be mirrored, linked, or reused.
class ContentRights {
  final ContentRightsType type;

  final String? license;

  final String? holder;

  final String? notes;

  const ContentRights({
    required this.type,
    required this.license,
    required this.holder,
    required this.notes,
  });

  factory ContentRights.fromJson(Map<String, dynamic> json) {
    return ContentRights(
      type: rightsTypeFromString(json['type'] as String),
      license: json['license'] as String?,
      holder: json['holder'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
