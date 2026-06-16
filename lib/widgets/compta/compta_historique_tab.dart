import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/comptabilite.dart';
import '../../models/demande_a_payer.dart';
import '../../providers/auth_provider.dart';
import '../../theme/aroma_theme.dart';
import '../../utils/format_utils.dart';
import '../../widgets/entity_scope_selector.dart';
import '../../widgets/modern_bottom_sheet.dart';
import 'compta_detail_content.dart';
import 'compta_ui.dart';

typedef ComptaHistoriqueSubTab = String;

abstract final class ComptaHistoriqueTabs {
  static const operations = 'operations';
  static const caisse = 'caisse';
  static const factures = 'factures';
  static const recettes = 'recettes';
  static const depenses = 'depenses';

  static const all = [
    ComptaTabConfig(operations, 'Opérations de caisse', Icons.receipt_long_outlined),
    ComptaTabConfig(caisse, 'Caisse', Icons.storefront_outlined),
    ComptaTabConfig(factures, 'Factures payées', Icons.description_outlined),
    ComptaTabConfig(recettes, 'Prévisions recettes', Icons.trending_up_rounded),
    ComptaTabConfig(depenses, 'Prévisions dépenses', Icons.trending_down_rounded),
  ];
}

class ComptaHistoriqueTab extends StatefulWidget {
  const ComptaHistoriqueTab({super.key});

  @override
  State<ComptaHistoriqueTab> createState() => _ComptaHistoriqueTabState();
}

class _ComptaHistoriqueTabState extends State<ComptaHistoriqueTab>
    with EntityScopeReloadMixin {
  String _subTab = ComptaHistoriqueTabs.operations;
  String _monthKey = currentMonthIso();
  String _search = '';
  bool _loading = true;
  String? _error;

  List<TransactionComptable> _operations = [];
  List<CaisseDemandeHistorique> _caisse = [];
  List<FacturationCompta> _factures = [];
  List<PrevisionRecetteCompta> _recettes = [];
  List<DemandeAPayer> _depenses = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  String get _monthDateMin => '$_monthKey-01';

  String get _monthDateMax {
    final parts = _monthKey.split('-');
    if (parts.length < 2) return _monthDateMin;
    final y = int.tryParse(parts[0]) ?? DateTime.now().year;
    final m = int.tryParse(parts[1]) ?? DateTime.now().month;
    final last = DateTime(y, m + 1, 0);
    return '${last.year.toString().padLeft(4, '0')}-'
        '${last.month.toString().padLeft(2, '0')}-'
        '${last.day.toString().padLeft(2, '0')}';
  }

  void _shiftMonth(int delta) {
    final parts = _monthKey.split('-');
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
      _monthKey = '${y.toString().padLeft(4, '0')}-'
          '${m.toString().padLeft(2, '0')}';
    });
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<AuthProvider>().api;
      switch (_subTab) {
        case ComptaHistoriqueTabs.operations:
          final ops = await api.listTransactionsComptable(
            limit: 500,
            historique: true,
            dateDebut: _monthDateMin,
            dateFin: _monthDateMax,
          );
          if (!mounted) return;
          setState(() {
            _operations = ops;
            _loading = false;
          });
        case ComptaHistoriqueTabs.caisse:
          final caisse = await api.listCaisseHistoriqueDemandes(
            dateDebut: _monthDateMin,
            dateFin: _monthDateMax,
          );
          if (!mounted) return;
          setState(() {
            _caisse = caisse;
            _loading = false;
          });
        case ComptaHistoriqueTabs.factures:
          final factures = await api.listCaisseHistoriqueFacturesPayees();
          if (!mounted) return;
          setState(() {
            _factures = factures;
            _loading = false;
          });
        case ComptaHistoriqueTabs.recettes:
          final recettes =
              await api.listCaisseHistoriquePrevisionsRecettesPayees();
          if (!mounted) return;
          setState(() {
            _recettes = recettes;
            _loading = false;
          });
        case ComptaHistoriqueTabs.depenses:
          final depenses =
              await api.listCaisseHistoriquePrevisionsDepensesPayees();
          if (!mounted) return;
          setState(() {
            _depenses = depenses;
            _loading = false;
          });
        default:
          if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _selectSubTab(String tab) {
    if (_subTab == tab) return;
    setState(() => _subTab = tab);
    _reload();
  }

  bool _matchesSearch(String text) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return true;
    return text.toLowerCase().contains(q);
  }

  bool _inMonth(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return true;
    return isoDate.startsWith(_monthKey);
  }

  @override
  Widget build(BuildContext context) {
    watchEntityScope(_reload);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ComptaTabPills(
          tabs: ComptaHistoriqueTabs.all,
          selected: _subTab,
          onSelected: _selectSubTab,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _reload,
            child: _loading
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: CircularProgressIndicator()),
                    ],
                  )
                : _error != null
                    ? ListView(
                        children: [
                          const SizedBox(height: 48),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Text(_error!, textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: _reload,
                                  child: const Text('Réessayer'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          const ComptaSectionHeader(
                            title: 'Mon historique',
                            subtitle: 'Opérations validées et éléments payés',
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => _shiftMonth(-1),
                                icon: const Icon(Icons.chevron_left_rounded),
                              ),
                              Expanded(
                                child: Text(
                                  monthLabelFr(_monthKey),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _shiftMonth(1),
                                icon: const Icon(Icons.chevron_right_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            decoration: const InputDecoration(
                              hintText: 'Rechercher…',
                              prefixIcon: Icon(Icons.search_rounded),
                            ),
                            onChanged: (v) => setState(() => _search = v),
                          ),
                          const SizedBox(height: 16),
                          ..._buildSubTabContent(),
                          const SizedBox(height: 24),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSubTabContent() {
    switch (_subTab) {
      case ComptaHistoriqueTabs.operations:
        return _buildOperations();
      case ComptaHistoriqueTabs.caisse:
        return _buildCaisse();
      case ComptaHistoriqueTabs.factures:
        return _buildFactures();
      case ComptaHistoriqueTabs.recettes:
        return _buildRecettes();
      case ComptaHistoriqueTabs.depenses:
        return _buildDepenses();
      default:
        return const [];
    }
  }

  List<Widget> _buildOperations() {
    final rows = _operations.where((t) {
      if (!_inMonth(t.dateTransaction)) return false;
      return _matchesSearch(
        '${t.descriptionAffichee} ${t.site ?? ''} ${t.demandeAuteur ?? ''}',
      );
    }).toList();

    if (rows.isEmpty) {
      return const [
        ComptaEmptyState(
          title: 'Aucune opération dans l\'historique',
          icon: Icons.history_rounded,
        ),
      ];
    }

    return rows
        .map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _HistoriqueCard(
              title: t.descriptionAffichee,
              subtitle: transactionListSubtitle(t),
              amount: fmtFcfa(t.isDepense ? t.debit : t.credit),
              amountColor: t.isDepense
                  ? const Color(0xFFB91C1C)
                  : ComptaUi.gradientStart,
              onTap: () => _showOperationDetail(t),
            ),
          ),
        )
        .toList();
  }

  List<Widget> _buildCaisse() {
    final rows = _caisse.where((d) {
      return _matchesSearch(
        '${d.raisonBonCommande} ${d.client} ${d.auteur ?? ''}',
      );
    }).toList();

    if (rows.isEmpty) {
      return const [
        ComptaEmptyState(
          title: 'Aucune opération caisse enregistrée',
          icon: Icons.storefront_outlined,
        ),
      ];
    }

    return rows
        .map(
          (d) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _HistoriqueCard(
              title: d.raisonBonCommande,
              subtitle: demandeListSubtitle(d, dateJourCaisse: d.dateJourCaisse),
              amount: fmtFcfa(d.montantAttendu ?? d.montantDemande),
              onTap: () => _showDemandeDetail(d),
            ),
          ),
        )
        .toList();
  }

  List<Widget> _buildFactures() {
    final rows = _factures.where((f) {
      if (!_inMonth(f.mois)) return false;
      return _matchesSearch(
        '${f.dolibarrRef ?? ''} ${f.clientNom ?? ''} ${f.mois}',
      );
    }).toList();

    if (rows.isEmpty) {
      return const [
        ComptaEmptyState(
          title: 'Aucune facture payée enregistrée',
          icon: Icons.description_outlined,
        ),
      ];
    }

    return rows
        .map(
          (f) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _HistoriqueCard(
              title: f.dolibarrRef?.trim().isNotEmpty == true
                  ? f.dolibarrRef!.trim()
                  : 'Facture ${f.mois}',
              subtitle:
                  '${f.clientNom ?? 'Client'} · ${formatDateFr(f.dechargeEnvoyeeLe)}',
              amount: fmtFcfa(f.montantFacture),
              onTap: () => _showFactureDetail(f),
            ),
          ),
        )
        .toList();
  }

  List<Widget> _buildRecettes() {
    final rows = _recettes.where((r) {
      if (!_inMonth(r.datePaiementPrevue)) return false;
      return _matchesSearch(
        '${r.libelle} ${r.clientAffiche} ${r.createdByEmail ?? ''}',
      );
    }).toList();

    if (rows.isEmpty) {
      return const [
        ComptaEmptyState(
          title: 'Aucune prévision recette payée',
          icon: Icons.trending_up_rounded,
        ),
      ];
    }

    return rows
        .map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _HistoriqueCard(
              title: r.libelle,
              subtitle:
                  '${r.clientAffiche} · ${formatDateFr(r.datePaiementPrevue)}',
              amount: fmtFcfa(r.montant),
              amountColor: ComptaUi.gradientStart,
              onTap: () => _showRecetteDetail(r),
            ),
          ),
        )
        .toList();
  }

  List<Widget> _buildDepenses() {
    final rows = _depenses.where((d) {
      if (!_inMonth(d.dateADecaisser)) return false;
      return _matchesSearch(
        '${d.raisonBonCommande} ${d.client} ${d.auteur ?? ''}',
      );
    }).toList();

    if (rows.isEmpty) {
      return const [
        ComptaEmptyState(
          title: 'Aucune prévision dépense payée',
          icon: Icons.trending_down_rounded,
        ),
      ];
    }

    return rows
        .map(
          (d) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _HistoriqueCard(
              title: d.raisonBonCommande,
              subtitle: demandeListSubtitle(d),
              amount: fmtFcfa(d.montantAttendu ?? d.montantDemande),
              amountColor: const Color(0xFFB45309),
              onTap: () => _showDemandeDetail(d),
            ),
          ),
        )
        .toList();
  }

  void _showOperationDetail(TransactionComptable t) {
    _showDetailSheet(
      title: 'Opération de caisse',
      children: buildTransactionDetailContent(
        t,
        showValidationDate: true,
      ),
    );
  }

  void _showDemandeDetail(DemandeAPayer d) {
    final dateJourCaisse =
        d is CaisseDemandeHistorique ? d.dateJourCaisse : null;
    _showDetailSheet(
      title: 'Détail opération',
      children: buildDemandeDetailContent(
        d,
        dateJourCaisse: dateJourCaisse,
      ),
    );
  }

  void _showFactureDetail(FacturationCompta f) {
    _showDetailSheet(
      title: 'Facture payée',
      children: [
        ComptaDetailRow('Client', f.clientNom ?? '—'),
        ComptaDetailRow('Réf. facture', f.dolibarrRef ?? '—'),
        ComptaDetailRow('Mois', f.mois),
        ComptaDetailRow('Montant', fmtFcfa(f.montantFacture)),
        ComptaDetailRow(
          'Date création',
          formatDateFr(f.dolibarrDateCreation),
        ),
        ComptaDetailRow(
          'Décharge déposée',
          formatDateFr(f.dechargeEnvoyeeLe),
        ),
      ],
    );
  }

  void _showRecetteDetail(PrevisionRecetteCompta r) {
    _showDetailSheet(
      title: 'Prévision recette payée',
      children: [
        ComptaDetailRow('Libellé', r.libelle),
        ComptaDetailRow('Client', r.clientAffiche),
        ComptaDetailRow('Montant', fmtFcfa(r.montant)),
        ComptaDetailRow('Date prévue', formatDateFr(r.datePaiementPrevue)),
        ComptaDetailRow('Auteur', r.createdByEmail ?? '—'),
        ComptaDetailRow(
          'Marqué payé le',
          formatDateFr(r.dateMarquePaye?.substring(0, 10)),
        ),
        if (r.observation != null && r.observation!.trim().isNotEmpty)
          ComptaDetailRow('Observation', r.observation!),
      ],
    );
  }

  void _showDetailSheet({
    required String title,
    required List<Widget> children,
  }) {
    showModernDetailSheet(
      context: context,
      title: title,
      theme: ModernSheetThemes.compta,
      children: children,
    );
  }
}

class _HistoriqueCard extends StatelessWidget {
  const _HistoriqueCard({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.onTap,
    this.amountColor,
  });

  final String title;
  final String subtitle;
  final String amount;
  final VoidCallback onTap;
  final Color? amountColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AromaColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE4E4E7)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AromaColors.zinc900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AromaColors.zinc500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  amount,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: amountColor ?? AromaColors.zinc800,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AromaColors.zinc500,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
