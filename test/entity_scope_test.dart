import 'package:aroma_jpc/utils/entity_scope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('syncEntityWithAllowed', () {
    test('préfère le pays collaborateur à CM quand rien n’est stocké', () {
      expect(
        syncEntityWithAllowed(
          stored: null,
          allowed: const ['CM', 'CI'],
          canEntityScopeAllFlag: false,
          preferredEntityCode: 'CI',
        ),
        'CI',
      );
    });

    test('conserve le pays déjà choisi par l’utilisateur', () {
      expect(
        syncEntityWithAllowed(
          stored: 'CM',
          allowed: const ['CM', 'CI'],
          canEntityScopeAllFlag: false,
          preferredEntityCode: 'CI',
        ),
        'CM',
      );
    });
  });

  group('applyEntityScopeOnLogin', () {
    test('positionne le pays par défaut à la connexion', () {
      expect(
        applyEntityScopeOnLogin(
          allowed: const ['CM', 'CI'],
          canEntityScopeAllFlag: false,
          defaultEntityCode: 'CI',
        ),
        'CI',
      );
    });

    test('écrase un pays précédemment stocké', () {
      expect(
        applyEntityScopeOnLogin(
          allowed: const ['CM', 'CI'],
          canEntityScopeAllFlag: false,
          defaultEntityCode: 'CI',
        ),
        'CI',
      );
    });
  });
}
