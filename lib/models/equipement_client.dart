class EquipementClient {
  EquipementClient({
    required this.id,
    required this.idClients,
    this.idAgence,
    this.emplacement,
    this.typeDiffuseur,
    this.reference,
  });

  final String id;
  final String idClients;
  final String? idAgence;
  final String? emplacement;
  final String? typeDiffuseur;
  final String? reference;

  static String? _str(dynamic v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  factory EquipementClient.fromJson(Map<String, dynamic> m) {
    return EquipementClient(
      id: '${m['id']}',
      idClients: '${m['id_clients']}',
      idAgence: m['id_agence']?.toString(),
      emplacement: _str(m['emplacement']),
      typeDiffuseur: _str(m['type_diffuseur']),
      reference: _str(m['reference']),
    );
  }
}
