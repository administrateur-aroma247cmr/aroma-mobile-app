import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/bon_commande.dart';
import '../models/demande_a_payer.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../utils/document_urls.dart';
import '../utils/format_utils.dart';

const _statutSoumisDemande = 'Soumis en attente de validations';
const _statutValideHierarchie = 'Validé par Hierachie';
const _statutNonValide = 'Non Valide';
const _statutPaye = 'Paye';
const _statutNonEffectue = 'Non effectué';

/// Fenêtre calendaire locale J-7 à J (inclus), alignée sur `hierarchieDemandesDateWindowBounds` du CRM web.
({String min, String max}) _hierarchieDemandesDateWindowBounds() {
  final now = DateTime.now();
  final maxD = DateTime(now.year, now.month, now.day);
  final minD = maxD.subtract(const Duration(days: 7));
  String fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
  return (min: fmt(minD), max: fmt(maxD));
}

String _fmtFcfa(num v) => '${v.round()} F CFA';

String _formatDateFr(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final parts = iso.split('-');
  if (parts.length >= 3) {
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }
  return iso;
}

String _labelBonFournisseurStatut(String s) {
  switch (s) {
    case 'en_attente_validation_interne':
      return 'En attente validation interne';
    case 'en_attente_confirmation_interne':
      return 'En attente confirmation interne';
    case 'validation_interne':
      return 'Validation interne';
    case 'commande_validee_fournisseur':
      return 'Commande validée fournisseur';
    default:
      return s.isEmpty ? '—' : s;
  }
}

String _labelBonInterneStatut(String s) {
  switch (s) {
    case 'validation_interne':
    case 'en_attente':
      return 'En attente validation';
    case 'valide':
      return 'Validé (compta)';
    case 'refuse':
      return 'Refusé';
    default:
      return s.isEmpty ? '—' : s;
  }
}

Future<void> _openDocumentPath(BuildContext context, String? path) async {
  if (path == null || path.trim().isEmpty) return;
  final url = documentOpenUrl(path.trim());
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!context.mounted) return;
  if (!ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Impossible d’ouvrir le document.')),
    );
  }
}

class MaValidationScreen extends StatefulWidget {
  const MaValidationScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<MaValidationScreen> createState() => _MaValidationScreenState();
}

class _MaValidationScreenState extends State<MaValidationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  bool _loading = true;
  String? _loadError;
  List<DemandeAPayer> _demandesRaw = [];
  List<BonCommandeFournisseurLite> _bonsF = [];
  List<BonCommandeInterneLite> _bonsI = [];

  final Set<String> _selectedDemandeIds = {};
  String _searchDemandes = '';
  String _searchBonsF = '';
  List<DemandeAPayer> _historiqueRaw = [];
  String _searchHistoriqueAuteur = '';
  String _historiqueMonthKey = currentMonthIso();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (!auth.isPrivilegedStaff) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accès réservé (rôle hiérarchique).'),
          ),
        );
        Navigator.of(context).pop();
        return;
      }
      _reload();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final api = context.read<AuthProvider>().api;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        api.listDemandesAPayer(statut: _statutSoumisDemande),
        api.listBonsCommandeFournisseur(),
        api.listBonsCommandeInterne(),
        api.listDemandesAPayer(statut: _statutValideHierarchie),
        api.listDemandesAPayer(statut: _statutNonValide),
        api.listDemandesAPayer(statut: _statutPaye),
        api.listDemandesAPayer(statut: _statutNonEffectue),
      ]);
      if (!mounted) return;
      final historiqueMap = <String, DemandeAPayer>{};
      for (final list in results.sublist(3)) {
        for (final d in list as List<DemandeAPayer>) {
          historiqueMap[d.id] = d;
        }
      }
      final historique = historiqueMap.values.toList()
        ..sort((a, b) {
          final da = DateTime.tryParse(a.createdAt ?? '')?.millisecondsSinceEpoch ?? 0;
          final db = DateTime.tryParse(b.createdAt ?? '')?.millisecondsSinceEpoch ?? 0;
          return db.compareTo(da);
        });
      setState(() {
        _demandesRaw = results[0] as List<DemandeAPayer>;
        _bonsF = results[1] as List<BonCommandeFournisseurLite>;
        _bonsI = results[2] as List<BonCommandeInterneLite>;
        _historiqueRaw = historique;
        _loading = false;
        _selectedDemandeIds.removeWhere(
          (id) => !_demandesInWindow.any((d) => d.id == id),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  List<DemandeAPayer> get _demandesInWindow {
    final bounds = _hierarchieDemandesDateWindowBounds();
    return _demandesRaw.where((d) {
      final k = d.dateADecaisser;
      if (k == null) return false;
      return k.compareTo(bounds.min) >= 0 && k.compareTo(bounds.max) <= 0;
    }).toList();
  }

  List<DemandeAPayer> get _filteredDemandes {
    final q = _searchDemandes.trim().toLowerCase();
    final list = _demandesInWindow;
    if (q.isEmpty) return list;
    return list.where((d) {
      return d.client.toLowerCase().contains(q) ||
          d.raisonBonCommande.toLowerCase().contains(q) ||
          (d.auteur ?? '').toLowerCase().contains(q) ||
          (d.dateADecaisser ?? '').toLowerCase().contains(q);
    }).toList();
  }

  List<BonCommandeFournisseurLite> get _bonsFHierarchy {
    return _bonsF.where((b) {
      return b.statut == 'en_attente_validation_interne' ||
          b.statut == 'en_attente_confirmation_interne';
    }).toList();
  }

  List<BonCommandeFournisseurLite> get _filteredBonsF {
    final q = _searchBonsF.trim().toLowerCase();
    final list = _bonsFHierarchy;
    if (q.isEmpty) return list;
    return list
        .where(
          (b) =>
              b.reference.toLowerCase().contains(q) ||
              b.fournisseurNom.toLowerCase().contains(q),
        )
        .toList();
  }

  List<BonCommandeInterneLite> get _bonsIAttente {
    return _bonsI
        .where(
          (b) => b.statut == 'validation_interne' || b.statut == 'en_attente',
        )
        .toList();
  }

  String _monthKeyFromIso(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final m = RegExp(r'^(\d{4}-\d{2})').firstMatch(iso.trim());
    return m?.group(1) ?? '';
  }

  List<DemandeAPayer> get _filteredHistorique {
    final auteurQ = _searchHistoriqueAuteur.trim().toLowerCase();
    return _historiqueRaw.where((d) {
      if (auteurQ.isNotEmpty &&
          !(d.auteur ?? '').toLowerCase().contains(auteurQ)) {
        return false;
      }
      if (_historiqueMonthKey.isEmpty) return true;
      final sourceMonth =
          _monthKeyFromIso(d.createdAt).isNotEmpty
              ? _monthKeyFromIso(d.createdAt)
              : _monthKeyFromIso(d.dateADecaisser);
      return sourceMonth == _historiqueMonthKey;
    }).toList();
  }

  void _shiftHistoriqueMonth(int delta) {
    final parts = _historiqueMonthKey.split('-');
    if (parts.length < 2) return;
    var y = int.tryParse(parts[0]) ?? DateTime.now().year;
    var m = int.tryParse(parts[1]) ?? DateTime.now().month;
    m += delta;
    while (m < 1) {
      m += 12;
      y -= 1;
    }
    while (m > 12) {
      m -= 12;
      y += 1;
    }
    setState(() {
      _historiqueMonthKey =
          '$y-${m.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _patchDemandeStatut(DemandeAPayer d, String statut) async {
    final api = context.read<AuthProvider>().api;
    try {
      await api.patchDemandeAPayer(d.id, {'statut': statut});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(statut == _statutNonValide ? 'Demande refusée.' : 'Demande validée par la hiérarchie.')),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _bulkPatchDemandes(String statut) async {
    final api = context.read<AuthProvider>().api;
    final ids = _selectedDemandeIds.toList();
    if (ids.isEmpty) return;
    try {
      for (final id in ids) {
        await api.patchDemandeAPayer(id, {'statut': statut});
      }
      if (!mounted) return;
      setState(() => _selectedDemandeIds.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ids.length == 1 ? 'Demande mise à jour.' : '${ids.length} demandes mises à jour.')),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _validerBonF(BonCommandeFournisseurLite b) async {
    final api = context.read<AuthProvider>().api;
    final next = b.statut == 'en_attente_confirmation_interne'
        ? 'commande_validee_fournisseur'
        : 'validation_interne';
    try {
      await api.patchBonCommandeFournisseur(b.id, {'statut': next});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bon mis à jour.')),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _refuserBonF(BonCommandeFournisseurLite b) async {
    final api = context.read<AuthProvider>().api;
    try {
      await api.patchBonCommandeFournisseur(b.id, {
        'statut': 'refuse_validation_interne',
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bon refusé (hiérarchie).')),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _validerBonI(BonCommandeInterneLite b) async {
    final api = context.read<AuthProvider>().api;
    try {
      await api.patchBonCommandeInterne(b.id, {'statut': 'valide'});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bon interne validé.')),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _refuserBonI(BonCommandeInterneLite b) async {
    final api = context.read<AuthProvider>().api;
    try {
      await api.patchBonCommandeInterne(b.id, {'statut': 'refuse'});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bon interne refusé.')),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _showHistoriqueDemandeSheet(DemandeAPayer d) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AromaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final donne = d.montantDonneTotal;
        final hasRetour = donne > 0 ||
            (d.retour != null && d.retour!.isNotEmpty) ||
            (d.attenteRetourCaisse ?? '').isNotEmpty;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            16 + MediaQuery.of(ctx).padding.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Historique demande',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                _DetailRow('Statut', d.statut ?? '—'),
                _DetailRow('Client', d.client),
                _DetailRow('Raison', d.raisonBonCommande),
                _DetailRow('Auteur', d.auteur ?? '—'),
                _DetailRow('Validé par', d.valideParHierarchie ?? '—'),
                if ((d.payePar ?? '').isNotEmpty)
                  _DetailRow('Payé par', d.payePar!),
                _DetailRow(
                  'Date',
                  _formatDateFr(d.createdAt) != '—'
                      ? _formatDateFr(d.createdAt)
                      : _formatDateFr(d.dateADecaisser),
                ),
                _DetailRow('Date à décaisser', _formatDateFr(d.dateADecaisser)),
                _DetailRow('Montant demandé', _fmtFcfa(d.montantDemande)),
                if (d.montantAttendu != null)
                  _DetailRow('Montant attendu', _fmtFcfa(d.montantAttendu!)),
                if (hasRetour) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Retour caisse',
                    style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  if (d.montantEspece != null && d.montantEspece! > 0)
                    _DetailRow('Espèce', _fmtFcfa(d.montantEspece!)),
                  if (d.montantMomo != null && d.montantMomo! > 0)
                    _DetailRow('MoMo', _fmtFcfa(d.montantMomo!)),
                  if (d.montantOm != null && d.montantOm! > 0)
                    _DetailRow('Orange Money', _fmtFcfa(d.montantOm!)),
                  if (d.montantCheque != null && d.montantCheque! > 0)
                    _DetailRow('Chèque', _fmtFcfa(d.montantCheque!)),
                  if (donne > 0)
                    _DetailRow('Total donné', _fmtFcfa(donne)),
                  if (d.retour != null && d.retour!.isNotEmpty)
                    _DetailRow('Retour', d.retour!),
                  if ((d.attenteRetourCaisse ?? '').isNotEmpty)
                    _DetailRow('Attente retour', d.attenteRetourCaisse!),
                ],
                if (d.justificatifs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Pièces jointes',
                    style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...d.justificatifs.map(
                    (j) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(j.name),
                      trailing: const Icon(Icons.open_in_new_rounded),
                      onTap: () => _openDocumentPath(ctx, j.path),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDemandeSheet(DemandeAPayer d) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AromaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            16 + MediaQuery.of(ctx).padding.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Demande à payer',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                _DetailRow('Client', d.client),
                _DetailRow('Raison', d.raisonBonCommande),
                _DetailRow('Auteur', d.auteur ?? '—'),
                _DetailRow('Date à décaisser', _formatDateFr(d.dateADecaisser)),
                _DetailRow('Montant demandé', _fmtFcfa(d.montantDemande)),
                if (d.montantAttendu != null)
                  _DetailRow('Montant attendu', _fmtFcfa(d.montantAttendu!)),
                if ((d.raisonBonTransport ?? '').isNotEmpty)
                  _DetailRow('Transport', d.raisonBonTransport!),
                if (d.justificatifs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Pièces jointes',
                    style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...d.justificatifs.map(
                    (j) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(j.name),
                      trailing: const Icon(Icons.open_in_new_rounded),
                      onTap: () => _openDocumentPath(ctx, j.path),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _patchDemandeStatut(d, _statutValideHierarchie);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                        ),
                        child: const Text('Valider (hiérarchie)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _patchDemandeStatut(d, _statutNonValide);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade800,
                          side: BorderSide(color: Colors.red.shade200),
                        ),
                        child: const Text('Refuser'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Le retour caisse détaillé (montants, justificatifs supplémentaires) reste aligné sur le module web.',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: AromaColors.zinc500,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBonFSheet(BonCommandeFournisseurLite b) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AromaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            16 + MediaQuery.of(ctx).padding.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bon fournisseur',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                _DetailRow('Référence', b.reference),
                _DetailRow('Fournisseur', b.fournisseurNom),
                _DetailRow('Statut', _labelBonFournisseurStatut(b.statut)),
                _DetailRow('Total (cmd + transport)', _fmtFcfa(b.totalCommandeTransport)),
                if (b.lignes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Lignes', style: Theme.of(ctx).textTheme.titleSmall),
                  ...b.lignes.map(
                    (l) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.designation ?? l.ref ?? '—'),
                      subtitle: Text('Qté ${l.quantite}'),
                      trailing: l.montant != null ? Text(_fmtFcfa(l.montant!)) : null,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _validerBonF(b);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                  ),
                  child: Text(
                    b.statut == 'en_attente_confirmation_interne'
                        ? 'Valider retour fournisseur'
                        : 'Valider (hiérarchie)',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _refuserBonF(b);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade800,
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                  child: const Text('Refuser (hiérarchie)'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBonISheet(BonCommandeInterneLite b) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AromaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            16 + MediaQuery.of(ctx).padding.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bon interne',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                _DetailRow('Référence', b.reference),
                _DetailRow('Demande', b.demande),
                _DetailRow('Description', b.description),
                _DetailRow('Pour qui', b.pourQuiLabel),
                _DetailRow('Collaborateur', b.collaborateurNom ?? '—'),
                _DetailRow('Statut', _labelBonInterneStatut(b.statut)),
                if (b.lignes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Lignes', style: Theme.of(ctx).textTheme.titleSmall),
                  ...b.lignes.map(
                    (l) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.designation ?? l.ref ?? '—'),
                      subtitle: Text('Qté ${l.quantite}'),
                      trailing: l.montant != null ? Text(_fmtFcfa(l.montant!)) : null,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _validerBonI(b);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                  ),
                  child: const Text('Valider'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _refuserBonI(b);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade800,
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                  child: const Text('Refuser'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final window = _hierarchieDemandesDateWindowBounds();
    final selectable = _filteredDemandes
        .where((d) => d.statut == _statutSoumisDemande)
        .toList();
    final allSelected = selectable.isNotEmpty &&
        selectable.every((d) => _selectedDemandeIds.contains(d.id));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('Ma validation'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loading ? null : _reload,
                  tooltip: 'Actualiser',
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => context.read<AuthProvider>().logout(),
                  tooltip: 'Déconnexion',
                ),
              ],
              bottom: TabBar(
                controller: _tabs,
                tabs: const [
                  Tab(text: 'Demandes à payer'),
                  Tab(text: 'Bons de commande'),
                  Tab(text: 'Historique'),
                ],
              ),
            ),
      body: _loadError != null && !_loading
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _reload, child: const Text('Réessayer')),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                if (widget.embedded)
                  Material(
                    color: Theme.of(context).appBarTheme.backgroundColor,
                    elevation: 0.5,
                    child: TabBar(
                      controller: _tabs,
                      tabs: const [
                        Tab(text: 'Demandes à payer'),
                        Tab(text: 'Bons de commande'),
                        Tab(text: 'Historique'),
                      ],
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _reload,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Demandes « $_statutSoumisDemande » — fenêtre ${_formatDateFr(window.min)} → ${_formatDateFr(window.max)}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AromaColors.zinc500,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      decoration: const InputDecoration(
                                        hintText: 'Rechercher (client, raison, auteur…)',
                                        prefixIcon: Icon(Icons.search_rounded),
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      onChanged: (v) => setState(() => _searchDemandes = v),
                                    ),
                                    if (_demandesRaw.isNotEmpty && _demandesInWindow.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Text(
                                          'Aucune demande dans la fenêtre (date à décaisser entre J-7 et aujourd’hui).',
                                          style: TextStyle(color: AromaColors.zinc500),
                                        ),
                                      ),
                                    if (selectable.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            TextButton.icon(
                                              onPressed: () {
                                                setState(() {
                                                  if (allSelected) {
                                                    _selectedDemandeIds.clear();
                                                  } else {
                                                    _selectedDemandeIds
                                                      ..clear()
                                                      ..addAll(selectable.map((e) => e.id));
                                                  }
                                                });
                                              },
                                              icon: Icon(
                                                allSelected
                                                    ? Icons.deselect_rounded
                                                    : Icons.check_box_rounded,
                                              ),
                                              label: Text(allSelected ? 'Tout désélectionner' : 'Tout sélectionner'),
                                            ),
                                            FilledButton.icon(
                                              onPressed: _selectedDemandeIds.isEmpty
                                                  ? null
                                                  : () => _bulkPatchDemandes(_statutValideHierarchie),
                                              icon: const Icon(Icons.check_rounded, size: 18),
                                              label: Text('Valider (${_selectedDemandeIds.length})'),
                                              style: FilledButton.styleFrom(
                                                backgroundColor: const Color(0xFF059669),
                                              ),
                                            ),
                                            OutlinedButton.icon(
                                              onPressed: _selectedDemandeIds.isEmpty
                                                  ? null
                                                  : () => _bulkPatchDemandes(_statutNonValide),
                                              icon: const Icon(Icons.close_rounded, size: 18),
                                              label: Text('Refuser (${_selectedDemandeIds.length})'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.red.shade800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (_filteredDemandes.isEmpty)
                              const SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(child: Text('Aucune ligne à afficher.')),
                              )
                            else
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) {
                                    final d = _filteredDemandes[i];
                                    final canSelect = d.statut == _statutSoumisDemande;
                                    return Card(
                                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      child: ListTile(
                                        leading: canSelect
                                            ? Checkbox(
                                                value: _selectedDemandeIds.contains(d.id),
                                                onChanged: (v) {
                                                  setState(() {
                                                    if (v == true) {
                                                      _selectedDemandeIds.add(d.id);
                                                    } else {
                                                      _selectedDemandeIds.remove(d.id);
                                                    }
                                                  });
                                                },
                                              )
                                            : const SizedBox(width: 24),
                                        title: Text(
                                          d.raisonBonCommande,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          '${d.client} · ${_formatDateFr(d.dateADecaisser)} · ${_fmtFcfa(d.montantDemande)}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: const Icon(Icons.chevron_right_rounded),
                                        onTap: () => _showDemandeSheet(d),
                                      ),
                                    );
                                  },
                                  childCount: _filteredDemandes.length,
                                ),
                              ),
                          ],
                        ),
                      ),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _reload,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bons fournisseur en attente hiérarchie, et bons internes en attente de validation.',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AromaColors.zinc500,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      decoration: const InputDecoration(
                                        hintText: 'Rechercher bon fournisseur (réf., fournisseur)',
                                        prefixIcon: Icon(Icons.search_rounded),
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      onChanged: (v) => setState(() => _searchBonsF = v),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                                child: Text(
                                  'Fournisseur (${_filteredBonsF.length})',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ),
                            if (_filteredBonsF.isEmpty)
                              const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                  child: Text('Aucun bon fournisseur en attente hiérarchie.'),
                                ),
                              )
                            else
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) {
                                    final b = _filteredBonsF[i];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      child: ListTile(
                                        title: Text(b.reference),
                                        subtitle: Text(
                                          '${b.fournisseurNom} · ${_labelBonFournisseurStatut(b.statut)}',
                                        ),
                                        trailing: const Icon(Icons.chevron_right_rounded),
                                        onTap: () => _showBonFSheet(b),
                                      ),
                                    );
                                  },
                                  childCount: _filteredBonsF.length,
                                ),
                              ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                                child: Text(
                                  'Interne (${_bonsIAttente.length})',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ),
                            if (_bonsIAttente.isEmpty)
                              const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                  child: Text('Aucun bon interne en attente.'),
                                ),
                              )
                            else
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) {
                                    final b = _bonsIAttente[i];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      child: ListTile(
                                        title: Text(b.reference),
                                        subtitle: Text(
                                          '${b.demande} · ${_labelBonInterneStatut(b.statut)}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: const Icon(Icons.chevron_right_rounded),
                                        onTap: () => _showBonISheet(b),
                                      ),
                                    );
                                  },
                                  childCount: _bonsIAttente.length,
                                ),
                              ),
                            const SliverToBoxAdapter(child: SizedBox(height: 32)),
                          ],
                        ),
                      ),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _reload,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Historique des demandes validées par la hiérarchie et leur avancement en caisse.',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AromaColors.zinc500,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      decoration: const InputDecoration(
                                        hintText: 'Filtrer par auteur…',
                                        prefixIcon: Icon(Icons.search_rounded),
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      onChanged: (v) =>
                                          setState(() => _searchHistoriqueAuteur = v),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: () => _shiftHistoriqueMonth(-1),
                                          icon: const Icon(Icons.chevron_left_rounded),
                                          tooltip: 'Mois précédent',
                                        ),
                                        Expanded(
                                          child: Text(
                                            monthLabelFr(_historiqueMonthKey),
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _shiftHistoriqueMonth(1),
                                          icon: const Icon(Icons.chevron_right_rounded),
                                          tooltip: 'Mois suivant',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_filteredHistorique.isEmpty)
                              const SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: Text('Aucun historique pour ces filtres.'),
                                ),
                              )
                            else
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) {
                                    final d = _filteredHistorique[i];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      child: ListTile(
                                        title: Text(
                                          d.raisonBonCommande,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          '${d.client} · ${d.auteur ?? '—'} · ${d.statut ?? '—'}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: const Icon(Icons.chevron_right_rounded),
                                        onTap: () => _showHistoriqueDemandeSheet(d),
                                      ),
                                    );
                                  },
                                  childCount: _filteredHistorique.length,
                                ),
                              ),
                            const SliverToBoxAdapter(child: SizedBox(height: 32)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AromaColors.zinc500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
