import 'package:aroma_jpc/models/intervention.dart';
import 'package:aroma_jpc/utils/technician_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ctx = TechnicianMatchContext(
    collaborateurId: 'collab-1',
    technicienId: 'tech-1',
    nameVariants: const ['serge anoh'],
  );

  Intervention iv({String? idTechnicien, String? technicienNom}) => Intervention(
        id: 'iv-1',
        idTechnicien: idTechnicien,
        technicienNom: technicienNom,
      );

  test('assignation par id technicien', () {
    expect(
      isInterventionAssignedToTechnician(iv(idTechnicien: 'tech-1'), ctx),
      isTrue,
    );
    expect(
      canPerformTechnicianFieldActions(iv(idTechnicien: 'tech-1'), ctx),
      isTrue,
    );
  });

  test('assignation legacy id collaborateur', () {
    expect(
      isInterventionAssignedToTechnician(iv(idTechnicien: 'collab-1'), ctx),
      isTrue,
    );
  });

  test('autre technicien refusé', () {
    final other = iv(idTechnicien: 'tech-2');
    expect(isInterventionAssignedToTechnician(other, ctx), isFalse);
    expect(canPerformTechnicianFieldActions(other, ctx), isFalse);
  });

  test('sans contexte technicien refusé', () {
    expect(
      canPerformTechnicianFieldActions(iv(idTechnicien: 'tech-1'), null),
      isFalse,
    );
  });

  test('assignation par nom technicien', () {
    expect(
      isInterventionAssignedToTechnician(
        iv(technicienNom: 'MENAN SERGE ANOH'),
        ctx,
      ),
      isTrue,
    );
  });

  test('flag API is_assigned_to_me prime sur le contexte local', () {
    expect(
      canPerformTechnicianFieldActions(
        Intervention(id: 'iv-1', isAssignedToMe: true),
        null,
      ),
      isTrue,
    );
    expect(
      canPerformTechnicianFieldActions(
        Intervention(id: 'iv-1', isAssignedToMe: false),
        ctx,
      ),
      isFalse,
    );
  });

  test('isAssignedToMe false retombe sur le contexte local', () {
    expect(
      canPerformTechnicianFieldActions(
        Intervention(id: 'iv-1', idTechnicien: 'tech-1', isAssignedToMe: false),
        ctx,
      ),
      isTrue,
    );
  });
}
