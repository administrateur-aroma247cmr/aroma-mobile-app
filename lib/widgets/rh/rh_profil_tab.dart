import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/collaborateur.dart';
import '../../providers/auth_provider.dart';
import '../../utils/format_utils.dart';
import '../../widgets/entity_scope_selector.dart';
import 'rh_ui.dart';

class RhProfilTab extends StatefulWidget {
  const RhProfilTab({super.key, this.collaborateurId});

  final String? collaborateurId;

  @override
  State<RhProfilTab> createState() => _RhProfilTabState();
}

class _RhProfilTabState extends State<RhProfilTab> with EntityScopeReloadMixin {
  bool _loading = true;
  String? _error;
  Collaborateur? _collab;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final auth = context.read<AuthProvider>();
    final id = widget.collaborateurId ?? auth.collaborateurId;
    if (id == null) {
      setState(() {
        _loading = false;
        _error = 'Aucun profil collaborateur lié à ce compte.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final c = await auth.api.getCollaborateur(id);
      if (!mounted) return;
      setState(() {
        _collab = c;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    watchEntityScope(_reload);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return RhEmptyState(
        title: _error!,
        icon: Icons.person_off_outlined,
      );
    }
    final c = _collab!;
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RhProfileHero(
            name: c.fullName,
            poste: c.poste,
            subtitle: c.matricule != null && c.matricule!.isNotEmpty
                ? 'Matricule ${c.matricule}'
                : null,
          ),
          const SizedBox(height: 16),
          RhInfoSection(
            title: 'Coordonnées',
            icon: Icons.contact_mail_outlined,
            rows: [
              (label: 'Email pro', value: c.emailPro),
              (label: 'Email perso', value: c.emailPerso),
              (label: 'Tél. pro', value: c.telPro),
              (label: 'Tél. perso', value: c.telPerso),
              (label: 'Urgence', value: c.personneContactUrgence),
            ],
          ),
          const SizedBox(height: 12),
          RhInfoSection(
            title: 'Contrat',
            icon: Icons.work_outline_rounded,
            rows: [
              (label: 'Matricule', value: c.matricule),
              (label: 'Type contrat', value: c.typeContrat),
              (label: 'Catégorie', value: c.categorieSociale),
              (label: 'Entrée', value: formatDateFr(c.dateEntreeDebut)),
              (label: 'Embauche', value: formatDateFr(c.dateEmbauche)),
            ],
          ),
          const SizedBox(height: 12),
          RhInfoSection(
            title: 'Identité',
            icon: Icons.badge_outlined,
            rows: [
              (label: 'Naissance', value: formatDateFr(c.dateNaissance)),
              (label: 'Lieu', value: c.lieuNaissance),
              (label: 'CNI', value: c.cni),
            ],
          ),
        ],
      ),
    );
  }
}
