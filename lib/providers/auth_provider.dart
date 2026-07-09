import 'package:flutter/foundation.dart';

import '../models/caisse_metrics.dart';
import '../services/aroma_api.dart';
import '../services/entity_store.dart';
import '../services/token_store.dart';
import '../utils/auth_roles.dart';
import '../utils/entity_scope.dart';
import '../utils/module_access.dart' as mod;

class AuthProvider extends ChangeNotifier {
  AuthProvider({TokenStore? tokenStore, EntityStore? entityStore})
      : _tokenStore = tokenStore ?? TokenStore(),
        _entityStore = entityStore ?? EntityStore() {
    _wireApi();
  }

  final TokenStore _tokenStore;
  final EntityStore _entityStore;
  late AromaApi _api;

  AromaApi get api => _api;

  String? _token;
  bool _loading = false;
  bool _initialized = false;
  String? _error;
  bool _mustChangePassword = false;
  Map<String, dynamic>? _me;
  String? _currentEntityCode;

  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get loading => _loading;
  bool get initialized => _initialized;
  String? get lastError => _error;
  bool get mustChangePassword => _mustChangePassword;
  Map<String, dynamic>? get me => _me;

  String? get currentEntityCode => _currentEntityCode;

  bool get isEntityScopeAllActive => isEntityScopeAll(_currentEntityCode);

  List<String> get entityCodes => normalizeEntityCodes(_me?['entity_codes']);

  bool get canEntityScopeAll {
    final fromMe = _me?['can_entity_scope_all'];
    if (fromMe != null) return fromMe == true;
    if (isManager) return false;
    final r = (role ?? '').trim().toLowerCase();
    return r == 'admin' || r == 'ceo' || r == 'coordinateur';
  }

  bool get showEntitySelector => entityCodes.length > 1;

  /// Valeur API (`admin`, `ceo`, `collaborateur`, …).
  String? get role {
    final r = _me?['role'];
    return r is String ? r : null;
  }

  /// Même règle que le menu « Ma validation » du CRM web.
  bool get isPrivilegedStaff => isPrivilegedStaffRole(role);

  bool get isManager =>
      _me?['is_manager'] == true || isManagerRole(role);

  bool get isExecutive =>
      _me?['can_view_executive_recaps'] == true ||
      isManager ||
      isExecutiveRole(role);

  bool get isCaisseMaPageDirection =>
      isManager || isCaisseMaPageDirectionRole(role);

  bool get canViewAllTaches =>
      isManager || canViewAllTachesRole(role);

  bool get canViewCollaborateurRecaps =>
      _me?['can_view_collaborateur_recaps'] != false &&
      canViewCollaborateurRecapsRole(role);

  String? get collaborateurId {
    final id = _me?['collaborateur_id'];
    if (id == null) return null;
    final s = id.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// Flag explicite fiche RH (`/api/me` → est_technicien_terrain).
  bool get estTechnicienTerrain => _me?['est_technicien_terrain'] == true;

  /// Présent après migration backend ; absent sur anciennes versions API.
  bool get hasEstTechnicienTerrainFlag =>
      _me != null && _me!.containsKey('est_technicien_terrain');

  String? _technicienId;

  /// ID technicien CRM lié au collaborateur connecté (cache).
  String? get technicienId => _technicienId;

  Future<String?> ensureTechnicienId() async {
    if (_technicienId != null) return _technicienId;
    final collabId = collaborateurId;
    if (collabId == null) return null;
    try {
      final techs = await _api.listTechniciens();
      for (final t in techs) {
        if (t.idCollaborateur == collabId) {
          _technicienId = t.id;
          notifyListeners();
          return _technicienId;
        }
      }
      // Rétrocompat : technicien sans id_collaborateur — match par nom collaborateur.
      try {
        final collab = await _api.getCollaborateur(collabId);
        final names = <String>{
          collab.fullName.trim().toLowerCase(),
          collab.nom.trim().toLowerCase(),
        }..removeWhere((s) => s.isEmpty);
        for (final t in techs) {
          final n = (t.nom ?? '').trim().toLowerCase();
          if (n.isEmpty) continue;
          for (final name in names) {
            if (n == name || n.contains(name) || name.contains(n)) {
              _technicienId = t.id;
              notifyListeners();
              return _technicienId;
            }
          }
        }
      } catch (_) {}
    } catch (_) {}
    return null;
  }

  void cacheTechnicienId(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return;
    _technicienId = trimmed;
  }

  void _resetTechnicienCache() => _technicienId = null;

  /// Résolution id technicien : filtrage interventions (vue terrain uniquement).
  bool _needsTechnicienIdResolution() {
    if (hasEstTechnicienTerrainFlag) {
      return estTechnicienTerrain;
    }
    if (isPrivilegedStaff) return false;
    return true;
  }

  Future<void> _afterMeLoaded() async {
    await _syncEntityScope();
    if (_needsTechnicienIdResolution()) {
      await ensureTechnicienId();
    } else {
      _resetTechnicienCache();
    }
  }

  Map<String, String> get droits {
    final raw = _me?['droits'];
    if (raw is! Map) return const {};
    return raw.map(
      (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
    );
  }

  bool canAccess(String serviceId) => hasServiceAccess(
        droits,
        serviceId,
        privilegedStaff: isPrivilegedStaff,
      );

  bool canModify(String serviceId) => canModifyService(
        droits,
        serviceId,
        privilegedStaff: isPrivilegedStaff,
      );

  String? get userEmail {
    final e = _me?['email'];
    if (e is String && e.trim().isNotEmpty) {
      return e.trim().toLowerCase();
    }
    return null;
  }

  bool canShowHomeModule(String moduleId) => mod.canShowHomeModuleTile(
        moduleId,
        isPrivilegedStaff: isPrivilegedStaff,
        canAccessComptabilite: canAccess('comptabilite'),
        canAccessInterventions:
            canAccess('interventions') || estTechnicienTerrain,
      );

  bool get canCreateTache => mod.canCreateTache(
        isPrivilegedStaff: isPrivilegedStaff,
        canModifyTasks: canModify('tasks'),
      );

  bool get canDeleteTache => mod.canDeleteTache(
        isPrivilegedStaff: isPrivilegedStaff,
      );

  bool get canEditTache => mod.canEditTacheContent(
        isPrivilegedStaff: isPrivilegedStaff,
        canModifyTasks: canModify('tasks'),
        canViewAllTaches: canViewAllTaches,
      );

  bool get canCreateCaisseDemande =>
      mod.canCreateCaisseDemande(canModifyCaisse: canModify('caisse'));

  bool canAccessCaisseMaPage(MaCaisseAccess? access) =>
      mod.canAccessCaisseMaPage(
        isCaisseMaPageDirection: isCaisseMaPageDirection,
        isDesignatedCaissier: access?.isDesignatedCaissier == true,
        isDesignatedSuperviseurFermeture:
            access?.isDesignatedSuperviseurFermetureDraft == true,
      );

  bool get canValidateRhDemande => mod.canValidateRhDemande(
        isPrivilegedStaff: isPrivilegedStaff,
      );

  bool get canEditRecouvrement => mod.canEditRecouvrement(
        isPrivilegedStaff: isPrivilegedStaff,
        canAccessComptabilite: canAccess('comptabilite'),
        canModifyComptabilite: canModify('comptabilite'),
      );

  bool get canViewRhExecutiveTabs => mod.canViewRhExecutiveTabs(
        isExecutive: isExecutive,
        role: role,
      );

  bool canDeleteGalerieFile({required bool isUploader}) =>
      mod.canDeleteGalerieFile(
        isExecutive: isExecutive,
        isUploader: isUploader,
      );

  /// Création demande RH / absence (collaborateur, pas direction exécutive).
  bool get canCreateRhDemande {
    if (collaborateurId == null) return false;
    if (isExecutive) return false;
    return canModify('rh') ||
        canModify('tasks') ||
        (!isPrivilegedStaff && collaborateurId != null);
  }

  Future<void> setEntityCode(String code) async {
    final upper = normalizeEntityCode(code);
    if (upper.isEmpty) return;
    if (upper == entityScopeAll) {
      if (!canShowEntityScopeAll(
        entityCodes,
        canEntityScopeAllFlag: canEntityScopeAll,
      )) {
        return;
      }
    } else if (!entityCodes.contains(upper)) {
      return;
    }
    _currentEntityCode = upper;
    await _entityStore.write(upper);
    _wireApi();
    notifyListeners();
  }

  void _wireApi() {
    _api = AromaApi(
      getToken: () => _token,
      getEntityCode: () => _currentEntityCode,
    );
  }

  Future<void> _persistEntityCode(String code) async {
    _currentEntityCode = code;
    await _entityStore.write(code);
    _wireApi();
  }

  Future<void> _syncEntityScope({String? preferredEntityCode}) async {
    final stored = await _entityStore.read();
    final synced = syncEntityWithAllowed(
      stored: stored,
      allowed: entityCodes,
      canEntityScopeAllFlag: canEntityScopeAll,
      preferredEntityCode:
          preferredEntityCode ?? _me?['default_entity_code'] as String?,
    );
    if (synced != null && synced != _currentEntityCode) {
      await _persistEntityCode(synced);
    } else if (synced != null) {
      _currentEntityCode = synced;
    }
  }

  Future<void> _applyEntityScopeOnLogin(Map<String, dynamic> loginData) async {
    final allowed = normalizeEntityCodes(loginData['entity_codes']);
    if (allowed.isEmpty) return;
    final canAll = loginData['can_entity_scope_all'] == true;
    final defaultCode = loginData['default_entity_code'] as String?;
    final code = applyEntityScopeOnLogin(
      allowed: allowed,
      canEntityScopeAllFlag: canAll,
      defaultEntityCode: defaultCode,
    );
    if (code != null) {
      await _persistEntityCode(code);
    }
  }

  Future<void> initialize() async {
    _token = await _tokenStore.read();
    _wireApi();
    _resetTechnicienCache();
    if (isAuthenticated) {
      try {
        _me = await _api.me();
        await _afterMeLoaded();
      } catch (_) {
        _token = null;
        _currentEntityCode = null;
        await _tokenStore.clear();
        await _entityStore.clear();
        _wireApi();
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _error = null;
    _loading = true;
    notifyListeners();
    try {
      final data = await _api.login(email: email, password: password);
      _token = data['access_token'] as String?;
      _mustChangePassword = data['must_change_password'] == true;
      if (_token != null) {
        await _tokenStore.write(_token!);
        _wireApi();
        _resetTechnicienCache();
        await _applyEntityScopeOnLogin(data);
        try {
          _me = await _api.me();
          await _afterMeLoaded();
        } catch (_) {
          _me = null;
        }
      }
      _loading = false;
      notifyListeners();
      return isAuthenticated;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _me = null;
    _currentEntityCode = null;
    _resetTechnicienCache();
    _mustChangePassword = false;
    await _tokenStore.clear();
    await _entityStore.clear();
    _wireApi();
    notifyListeners();
  }

  Future<void> refreshMe() async {
    if (!isAuthenticated) return;
    try {
      _me = await _api.me();
      await _afterMeLoaded();
      notifyListeners();
    } catch (_) {}
  }
}
