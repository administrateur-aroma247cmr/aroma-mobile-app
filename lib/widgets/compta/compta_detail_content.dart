import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/comptabilite.dart';
import '../../models/demande_a_payer.dart';
import '../../theme/aroma_theme.dart';
import '../../utils/document_urls.dart';
import '../../utils/format_utils.dart';

class ComptaDetailRow extends StatelessWidget {
  const ComptaDetailRow(this.label, this.value, {super.key});

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
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AromaColors.zinc500, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AromaColors.zinc900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ComptaDetailSectionTitle extends StatelessWidget {
  const ComptaDetailSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

Future<void> openComptaDocument(BuildContext context, String? path) async {
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

class ComptaDemandeJustificatifsSection extends StatelessWidget {
  const ComptaDemandeJustificatifsSection({
    super.key,
    required this.justificatifs,
  });

  final List<DemandeJustificatif> justificatifs;

  @override
  Widget build(BuildContext context) {
    if (justificatifs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ComptaDetailSectionTitle('Pièces jointes'),
        ...justificatifs.map(
          (j) => ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.attach_file_rounded, size: 20),
            title: Text(j.name),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => openComptaDocument(context, j.path),
          ),
        ),
      ],
    );
  }
}

class ComptaPiecesJustificativesSection extends StatelessWidget {
  const ComptaPiecesJustificativesSection({
    super.key,
    required this.pieces,
  });

  final List<PieceJustificativeCompta> pieces;

  @override
  Widget build(BuildContext context) {
    if (pieces.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ComptaDetailSectionTitle('Pièces justificatives'),
        ...pieces.asMap().entries.map(
          (e) => ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.attach_file_rounded, size: 20),
            title: Text(e.value.displayName(e.key)),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () => openComptaDocument(context, e.value.documentPath),
          ),
        ),
      ],
    );
  }
}

List<Widget> buildTransactionDetailContent(
  TransactionComptable t, {
  bool showValidationDate = false,
}) {
  final rows = <Widget>[
    ComptaDetailRow('Date', formatDateFr(t.dateTransaction)),
    ComptaDetailRow('Type', t.isDepense ? 'Sortie' : 'Entrée'),
    ComptaDetailRow('Description', t.descriptionAffichee),
  ];

  void addIf(String label, String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return;
    rows.add(ComptaDetailRow(label, v));
  }

  addIf('Groupe', t.groupe);
  addIf('Sous-groupe', t.sousGroupe);
  addIf('Sous-catégorie', t.sousCategorie);
  addIf('Sous-désignation', t.sousDesignation);
  addIf('Site', t.site);
  addIf('Compte', t.compteAffiche);
  addIf('Agent', t.agent);
  addIf('Demandeur', t.demandeAuteur);
  addIf('N° facture', t.numeroFacture);
  addIf('Type facture', t.typeFacture);

  if (t.montantHt != null && t.montantHt! > 0) {
    rows.add(ComptaDetailRow('Montant HT', fmtFcfa(t.montantHt)));
  }
  if (t.tva != null && t.tva! > 0) {
    final tvaLabel = (t.typeTva ?? '').trim().isNotEmpty
        ? 'TVA (${t.typeTva})'
        : 'TVA';
    rows.add(ComptaDetailRow(tvaLabel, fmtFcfa(t.tva)));
  }
  if (t.montantTtc != null && t.montantTtc! > 0) {
    rows.add(ComptaDetailRow('Montant TTC', fmtFcfa(t.montantTtc)));
  }

  rows.add(
    ComptaDetailRow(
      t.isDepense ? 'Sortie' : 'Entrée',
      fmtFcfa(t.isDepense ? t.debit : t.credit),
    ),
  );

  if (t.retenuALaSource == true) {
    rows.add(const ComptaDetailRow('Retenu à la source', 'Oui'));
  }

  final obs = t.observationAffichee;
  if (obs != null) {
    rows.add(ComptaDetailRow('Observation', obs));
  }

  if (showValidationDate) {
    addIf('Date validation', formatDateFr(t.dateValidation));
  }

  rows.add(ComptaPiecesJustificativesSection(pieces: t.piecesJustificatives));

  return rows;
}

List<Widget> buildDemandeDetailContent(
  DemandeAPayer d, {
  String? dateJourCaisse,
}) {
  final rows = <Widget>[
    ComptaDetailRow('Statut', d.statut ?? '—'),
    ComptaDetailRow('Raison', d.raisonBonCommande),
  ];

  void addIf(String label, String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return;
    rows.add(ComptaDetailRow(label, v));
  }

  addIf('Complément', d.raisonBonTransport);
  rows.addAll([
    ComptaDetailRow('Client', d.client),
    ComptaDetailRow('Auteur', d.auteur ?? '—'),
    ComptaDetailRow('Validé par', d.valideParHierarchie ?? '—'),
  ]);
  addIf('Payé par', d.payePar);
  addIf('Date jour caisse', formatDateFr(dateJourCaisse));
  rows.add(ComptaDetailRow('Date à décaisser', formatDateFr(d.dateADecaisser)));
  addIf('Date de la demande', formatDateFr(d.createdAt?.substring(0, 10)));
  addIf('Date de paiement', formatDateFr(d.payeAt?.substring(0, 10)));
  rows.add(ComptaDetailRow('Montant demandé', fmtFcfa(d.montantDemande)));
  if (d.montantAttendu != null) {
    rows.add(ComptaDetailRow('Montant donné', fmtFcfa(d.montantAttendu)));
  }

  final donne = d.montantDonneTotal;
  final hasRetour = donne > 0 ||
      (d.retour ?? '').isNotEmpty ||
      (d.attenteRetourCaisse ?? '').isNotEmpty ||
      (d.montantEspece ?? 0) > 0 ||
      (d.montantMomo ?? 0) > 0 ||
      (d.montantOm ?? 0) > 0 ||
      (d.montantCheque ?? 0) > 0;

  if (hasRetour) {
    rows.add(const ComptaDetailSectionTitle('Retour caisse'));
    if ((d.montantEspece ?? 0) > 0) {
      rows.add(ComptaDetailRow('Espèce', fmtFcfa(d.montantEspece)));
    }
    if ((d.montantMomo ?? 0) > 0) {
      rows.add(ComptaDetailRow('MoMo', fmtFcfa(d.montantMomo)));
    }
    if ((d.montantOm ?? 0) > 0) {
      rows.add(ComptaDetailRow('Orange Money', fmtFcfa(d.montantOm)));
    }
    if ((d.montantCheque ?? 0) > 0) {
      rows.add(ComptaDetailRow('Chèque', fmtFcfa(d.montantCheque)));
    }
    if (donne > 0) {
      rows.add(ComptaDetailRow('Total donné', fmtFcfa(donne)));
    }
    addIf('Retour', d.retour);
    addIf('Attente retour', d.attenteRetourCaisse);
  } else {
    addIf('Retour', d.retour);
  }

  rows.add(ComptaDemandeJustificatifsSection(justificatifs: d.justificatifs));

  return rows;
}

String transactionListSubtitle(TransactionComptable t) {
  final parts = <String>[
    formatDateFr(t.dateTransaction),
    t.isDepense ? 'Sortie' : 'Entrée',
    if ((t.compteAffiche ?? '').isNotEmpty) t.compteAffiche!,
    if ((t.demandeAuteur ?? '').trim().isNotEmpty) t.demandeAuteur!.trim(),
    if (t.piecesJustificatives.isNotEmpty)
      '${t.piecesJustificatives.length} PJ',
  ];
  return parts.join(' · ');
}

String demandeListSubtitle(DemandeAPayer d, {String? dateJourCaisse}) {
  final parts = <String>[
    d.client,
    if ((d.auteur ?? '').trim().isNotEmpty) d.auteur!.trim(),
    formatDateFr(d.dateADecaisser),
    if ((dateJourCaisse ?? '').trim().isNotEmpty)
      'Jour ${formatDateFr(dateJourCaisse)}',
    d.statut ?? '—',
    if (d.justificatifs.isNotEmpty) '${d.justificatifs.length} PJ',
  ];
  return parts.join(' · ');
}
