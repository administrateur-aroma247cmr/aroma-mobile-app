import 'package:aroma_jpc/models/intervention.dart';
import 'package:aroma_jpc/utils/intervention_technician_actions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Intervention iv({String? etatApp}) => Intervention(
        id: '1',
        etatApp: etatApp,
      );

  test('masque les interventions avec rapport enregistré', () {
    expect(
      isInterventionVisibleForTechnicianTerrain(
        iv(etatApp: "Rapport d'intervention"),
      ),
      isFalse,
    );
    expect(
      isInterventionVisibleForTechnicianTerrain(iv(etatApp: 'Démarré')),
      isTrue,
    );
  });

  test('plus de bouton rapport après enregistrement', () {
    expect(
      technicianInterventionAction("Rapport d'intervention"),
      TechnicianInterventionAction.none,
    );
    expect(
      technicianInterventionAction('Traité'),
      TechnicianInterventionAction.creerRapport,
    );
  });
}
