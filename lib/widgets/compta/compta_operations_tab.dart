import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/comptabilite.dart';
import '../../providers/auth_provider.dart';
import '../../theme/aroma_theme.dart';
import '../../utils/format_utils.dart';
import '../../widgets/entity_scope_selector.dart';
import '../../widgets/modern_bottom_sheet.dart';
import 'compta_detail_content.dart';
import 'compta_ui.dart';

class ComptaOperationsTab extends StatefulWidget {
  const ComptaOperationsTab({super.key});

  @override
  State<ComptaOperationsTab> createState() => _ComptaOperationsTabState();
}

class _ComptaOperationsTabState extends State<ComptaOperationsTab>
    with EntityScopeReloadMixin {
  bool _loading = true;
  String? _error;
  List<TransactionComptable> _rows = [];
  String _search = '';
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<AuthProvider>().api;
      final rows = await api.listTransactionsComptable(
        limit: 500,
        validationOk: false,
      );
      if (!mounted) return;
      setState(() {
        _rows = rows;
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

  List<TransactionComptable> get _filtered {
    final q = _search.trim().toLowerCase();
    return _rows.where((t) {
      if (_filterType == 'depense' && !t.isDepense) return false;
      if (_filterType == 'recette' && t.isDepense) return false;
      if (q.isEmpty) return true;
      return t.descriptionAffichee.toLowerCase().contains(q) ||
          (t.site ?? '').toLowerCase().contains(q) ||
          (t.demandeAuteur ?? '').toLowerCase().contains(q);
    }).toList();
  }

  void _showDetail(TransactionComptable t) {
    showModernDetailSheet(
      context: context,
      title: 'Opération de caisse',
      theme: ModernSheetThemes.compta,
      children: buildTransactionDetailContent(t),
    );
  }

  @override
  Widget build(BuildContext context) {
    watchEntityScope(_reload);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _reload, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    final rows = _filtered;

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ComptaSectionHeader(
            title: 'Les opérations de caisse',
            subtitle: 'Opérations à traiter — aligné CRM web',
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Rechercher…',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _TypeChip(
                label: 'Tout',
                selected: _filterType == 'all',
                onTap: () => setState(() => _filterType = 'all'),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: 'Entrées',
                selected: _filterType == 'recette',
                color: const Color(0xFF059669),
                onTap: () => setState(() => _filterType = 'recette'),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: 'Sorties',
                selected: _filterType == 'depense',
                color: const Color(0xFFB91C1C),
                onTap: () => setState(() => _filterType = 'depense'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (rows.isEmpty)
            const ComptaEmptyState(
              title: 'Aucune opération à traiter',
              subtitle: 'Les opérations validées sont dans Mon historique.',
              icon: Icons.receipt_long_outlined,
            )
          else
            ...rows.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _OperationTile(
                  transaction: t,
                  onTap: () => _showDetail(t),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _OperationTile extends StatelessWidget {
  const _OperationTile({required this.transaction, required this.onTap});

  final TransactionComptable transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final isDepense = t.isDepense;
    final amount = isDepense ? t.debit : t.credit;

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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (isDepense
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFECFDF5))
                        .withValues(alpha: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDepense
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 20,
                    color: isDepense
                        ? const Color(0xFFB91C1C)
                        : ComptaUi.gradientStart,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.descriptionAffichee,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AromaColors.zinc900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transactionListSubtitle(t),
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
                  fmtFcfa(amount),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDepense
                        ? const Color(0xFFB91C1C)
                        : ComptaUi.gradientStart,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? ComptaUi.accent;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: accent.withValues(alpha: 0.15),
      checkmarkColor: accent,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: selected ? accent : AromaColors.zinc800,
      ),
      side: BorderSide(
        color: selected ? accent.withValues(alpha: 0.4) : const Color(0xFFE4E4E7),
      ),
    );
  }
}
