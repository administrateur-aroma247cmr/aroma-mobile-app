class BusinessEntity {
  BusinessEntity({
    required this.code,
    required this.label,
    this.isActive = true,
  });

  final String code;
  final String label;
  final bool isActive;

  factory BusinessEntity.fromJson(Map<String, dynamic> m) {
    return BusinessEntity(
      code: '${m['code'] ?? ''}'.trim().toUpperCase(),
      label: '${m['label'] ?? m['code'] ?? ''}',
      isActive: m['is_active'] != false,
    );
  }
}
