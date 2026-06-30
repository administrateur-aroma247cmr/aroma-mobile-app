class AgenceClient {
  AgenceClient({
    required this.id,
    this.nomAgence,
    this.ville,
    this.idClients,
  });

  final String id;
  final String? nomAgence;
  final String? ville;
  final String? idClients;

  String get label {
    final n = (nomAgence ?? '').trim();
    return n.isNotEmpty ? n : id;
  }

  static String? _str(dynamic v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  factory AgenceClient.fromJson(Map<String, dynamic> m) {
    return AgenceClient(
      id: '${m['id']}',
      nomAgence: _str(m['nom_agence']),
      ville: _str(m['ville']),
      idClients: m['id_clients']?.toString(),
    );
  }
}
