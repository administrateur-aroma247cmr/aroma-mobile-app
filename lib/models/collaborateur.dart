class Collaborateur {
  Collaborateur({
    required this.id,
    required this.nom,
    required this.prenom,
    this.poste,
    this.telPro,
    this.telPerso,
    this.emailPro,
    this.emailPerso,
    this.dateNaissance,
    this.lieuNaissance,
    this.dateEntreeDebut,
    this.dateEmbauche,
    this.cni,
    this.typeContrat,
    this.categorieSociale,
    this.matricule,
    this.personneContactUrgence,
    this.entityCode,
  });

  final String id;
  final String nom;
  final String prenom;
  final String? poste;
  final String? telPro;
  final String? telPerso;
  final String? emailPro;
  final String? emailPerso;
  final String? dateNaissance;
  final String? lieuNaissance;
  final String? dateEntreeDebut;
  final String? dateEmbauche;
  final String? cni;
  final String? typeContrat;
  final String? categorieSociale;
  final String? matricule;
  final String? personneContactUrgence;
  final String? entityCode;

  String get fullName => '$prenom $nom'.trim();

  factory Collaborateur.fromJson(Map<String, dynamic> m) {
    return Collaborateur(
      id: '${m['id']}',
      nom: '${m['nom'] ?? ''}',
      prenom: '${m['prenom'] ?? ''}',
      poste: m['poste'] is String ? m['poste'] as String : null,
      telPro: m['tel_pro'] is String ? m['tel_pro'] as String : null,
      telPerso: m['tel_perso'] is String ? m['tel_perso'] as String : null,
      emailPro: m['email_pro'] is String ? m['email_pro'] as String : null,
      emailPerso: m['email_perso'] is String ? m['email_perso'] as String : null,
      dateNaissance:
          m['date_naissance'] is String ? m['date_naissance'] as String : null,
      lieuNaissance:
          m['lieu_naissance'] is String ? m['lieu_naissance'] as String : null,
      dateEntreeDebut: m['date_entree_debut'] is String
          ? m['date_entree_debut'] as String
          : null,
      dateEmbauche:
          m['date_embauche'] is String ? m['date_embauche'] as String : null,
      cni: m['cni'] is String ? m['cni'] as String : null,
      typeContrat:
          m['type_contrat'] is String ? m['type_contrat'] as String : null,
      categorieSociale: m['categorie_sociale'] is String
          ? m['categorie_sociale'] as String
          : null,
      matricule: m['matricule'] is String ? m['matricule'] as String : null,
      personneContactUrgence: m['personne_contact_urgence'] is String
          ? m['personne_contact_urgence'] as String
          : null,
      entityCode:
          m['entity_code'] is String ? m['entity_code'] as String : null,
    );
  }
}
