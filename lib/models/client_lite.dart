class ClientLite {
  ClientLite({required this.id, required this.nomClient});

  final String id;
  final String nomClient;

  factory ClientLite.fromJson(Map<String, dynamic> m) {
    return ClientLite(
      id: '${m['id']}',
      nomClient: '${m['nom_client'] ?? m['nom'] ?? ''}',
    );
  }
}
