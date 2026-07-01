// Barèmes transport terrain (aligné CRM web — transportTrajetsData.ts).

const villesTransport = ['Douala', 'Yaoundé'];

typedef VilleTransport = String;

final _trajetsDouala = <(String, String, int)>[
  ('Aéroport', 'Akwa', 700),
  ('Aéroport', 'Bali', 600),
  ('Aéroport', 'Bonanjo', 500),
  ('Aéroport', 'Bonamoussadi', 1400),
  ('Aéroport', 'Kotto', 1400),
  ('Aéroport', 'Bepanda', 1400),
  ('Aéroport', 'Bonaberi', 1500),
  ('Aéroport', 'Yassa', 400),
  ('Aéroport', 'Bonapriso', 700),
  ('Akwa', 'Bonapriso', 350),
  ('Akwa', 'Bonanjo', 350),
  ('Akwa', 'Bali', 300),
  ('Akwa', 'Deido', 400),
  ('Akwa', 'Bepanda', 400),
  ('Akwa', 'Bonamoussadi', 1000),
  ('Akwa', 'Kotto', 1000),
  ('Akwa', 'Makepe', 1600),
  ('Akwa', 'Bonaberi', 1000),
  ('Akwa', 'Bassa', 1200),
  ('Akwa', 'Ndokoti', 800),
  ('Akwa', 'Logbaba', 1000),
  ('Akwa', 'Yassa', 1500),
  ('Akwa', 'pk14', 1600),
  ('Bepanda', 'Bonanjo', 500),
  ('Bepanda', 'Bali', 500),
  ('Bepanda', 'Bonamoussadi', 700),
  ('Bepanda', 'Kotto', 700),
  ('Bepanda', 'Makepe', 900),
  ('Bepanda', 'Bonaberi', 700),
  ('Bepanda', 'Bassa', 900),
  ('Bepanda', 'Ndokoti', 500),
  ('Bepanda', 'Logbaba', 800),
  ('Bepanda', 'Yassa', 1400),
  ('Bepanda', 'pk14', 1400),
  ('Bonapriso', 'Bonanjo', 350),
  ('Bonapriso', 'Bali', 200),
  ('Bonapriso', 'Deido', 400),
  ('Bonapriso', 'Bepanda', 500),
  ('Bonapriso', 'Bonamoussadi', 1400),
  ('Bonapriso', 'Kotto', 1400),
  ('Bonapriso', 'Makepe', 1400),
  ('Bonapriso', 'Bonaberi', 1000),
  ('Bonapriso', 'Bassa', 1000),
  ('Bonapriso', 'Ndokoti', 700),
  ('Bonapriso', 'Logbaba', 1200),
  ('Bonapriso', 'Yassa', 1300),
  ('Bonapriso', 'pk14', 1400),
  ('Bonanjo', 'Bali', 350),
  ('Bonanjo', 'Deido', 400),
  ('Bonanjo', 'Bepanda', 500),
  ('Bonanjo', 'Bonamoussadi', 1200),
  ('Bonanjo', 'Kotto', 1200),
  ('Bonanjo', 'Makepe', 1400),
  ('Bonanjo', 'Bonaberi', 900),
  ('Bonanjo', 'Bassa', 1200),
  ('Bonanjo', 'Ndokoti', 1200),
  ('Bonanjo', 'Logbaba', 1100),
  ('Bonanjo', 'Yassa', 1400),
  ('Bonanjo', 'pk14', 1500),
  ('Bali', 'Deido', 500),
  ('Bali', 'Bepanda', 500),
  ('Bali', 'Bonamoussadi', 1200),
  ('Bali', 'Kotto', 1200),
  ('Bali', 'Makepe', 1400),
  ('Bali', 'Bonaberi', 900),
  ('Bali', 'Bassa', 1100),
  ('Bali', 'Ndokoti', 1200),
  ('Bali', 'Logbaba', 1100),
  ('Bali', 'Yassa', 1400),
  ('Bali', 'pk14', 1500),
  ('Deido', 'Bepanda', 400),
  ('Deido', 'Bonamoussadi', 1000),
  ('Deido', 'Kotto', 1000),
  ('Deido', 'Makepe', 1200),
  ('Deido', 'Bonaberi', 700),
  ('Deido', 'Bassa', 900),
  ('Deido', 'Ndokoti', 1000),
  ('Deido', 'Logbaba', 900),
  ('Deido', 'Yassa', 1200),
  ('Deido', 'pk14', 1300),
  ('Bonamoussadi', 'Kotto', 300),
  ('Bonamoussadi', 'Makepe', 400),
  ('Bonamoussadi', 'Bonaberi', 900),
  ('Bonamoussadi', 'Bassa', 800),
  ('Bonamoussadi', 'Ndokoti', 900),
  ('Bonamoussadi', 'Logbaba', 1000),
  ('Bonamoussadi', 'Yassa', 1400),
  ('Bonamoussadi', 'pk14', 1500),
  ('Kotto', 'Makepe', 300),
  ('Kotto', 'Bonaberi', 900),
  ('Kotto', 'Bassa', 800),
  ('Kotto', 'Ndokoti', 900),
  ('Kotto', 'Logbaba', 1000),
  ('Kotto', 'Yassa', 1400),
  ('Kotto', 'pk14', 1500),
  ('Makepe', 'Bonaberi', 1200),
  ('Makepe', 'Bassa', 900),
  ('Makepe', 'Ndokoti', 900),
  ('Makepe', 'Logbaba', 1100),
  ('Makepe', 'Yassa', 1400),
  ('Makepe', 'pk14', 1500),
  ('Bonaberi', 'Bassa', 1000),
  ('Bonaberi', 'Ndokoti', 1100),
  ('Bonaberi', 'Logbaba', 1200),
  ('Bonaberi', 'Yassa', 1500),
  ('Bonaberi', 'pk14', 1600),
  ('Bassa', 'Ndokoti', 400),
  ('Bassa', 'Logbaba', 600),
  ('Bassa', 'Yassa', 900),
  ('Bassa', 'pk14', 1000),
  ('Yassa', 'pk14', 600),
  ('Logbaba', 'Yassa', 600),
  ('Logbaba', 'pk14', 700),
];

final _trajetsYaounde = <(String, String, int)>[
  ('Mendong', 'Essos', 600),
  ('Mendong', 'Messassi', 1000),
  ('Mendong', 'Bastos', 700),
  ('Mendong', 'Odza', 700),
  ('Mendong', 'Boulevard du 20 mai', 500),
  ('Mendong', 'Kennedy', 500),
  ('Mendong', 'Kondengui', 600),
  ('Mendong', 'Biyem Assi', 350),
  ('Mendong', 'Ekounou', 800),
  ('Mendong', 'Dragage', 700),
  ('Mendong', 'Playce', 600),
  ('Mendong', 'Carrefour Intendance', 500),
  ('Mendong', 'Tsinga', 500),
  ('Mendong', 'Mvom Mbi', 400),
  ('Mendong', 'Centre Ville', 500),
  ('Essos', 'Messassi', 1000),
  ('Essos', 'Bastos', 700),
  ('Essos', 'Odza', 800),
  ('Essos', 'Boulevard du 20 mai', 500),
  ('Essos', 'Kennedy', 400),
  ('Essos', 'Kondengui', 500),
  ('Essos', 'Biyem Assi', 700),
  ('Essos', 'Ekounou', 500),
  ('Essos', 'Dragage', 400),
  ('Essos', 'Playce', 400),
  ('Essos', 'Carrefour Intendance', 400),
  ('Essos', 'Tsinga', 350),
  ('Essos', 'Mvom Mbi', 400),
  ('Essos', 'Centre Ville', 400),
  ('Messassi', 'Bastos', 500),
  ('Messassi', 'Odza', 1000),
  ('Messassi', 'Boulevard du 20 mai', 500),
  ('Messassi', 'Kennedy', 600),
  ('Messassi', 'Kondengui', 1000),
  ('Messassi', 'Biyem Assi', 1000),
  ('Messassi', 'Ekounou', 600),
  ('Messassi', 'Dragage', 500),
  ('Messassi', 'Playce', 500),
  ('Messassi', 'Carrefour Intendance', 500),
  ('Messassi', 'Tsinga', 600),
  ('Messassi', 'Mvom Mbi', 800),
  ('Messassi', 'Centre Ville', 600),
  ('Bastos', 'Odza', 1000),
  ('Bastos', 'Boulevard du 20 mai', 350),
  ('Bastos', 'Kennedy', 300),
  ('Bastos', 'Kondengui', 700),
  ('Bastos', 'Biyem Assi', 800),
  ('Bastos', 'Ekounou', 800),
  ('Bastos', 'Dragage', 300),
  ('Bastos', 'Playce', 300),
  ('Bastos', 'Carrefour Intendance', 400),
  ('Bastos', 'Tsinga', 200),
  ('Bastos', 'Mvom Mbi', 500),
  ('Bastos', 'Centre Ville', 400),
  ('Odza', 'Boulevard du 20 mai', 800),
  ('Odza', 'Kennedy', 800),
  ('Odza', 'Kondengui', 700),
  ('Odza', 'Biyem Assi', 800),
  ('Odza', 'Ekounou', 500),
  ('Odza', 'Dragage', 900),
  ('Odza', 'Playce', 900),
  ('Odza', 'Carrefour Intendance', 700),
  ('Odza', 'Tsinga', 900),
  ('Odza', 'Mvom Mbi', 500),
  ('Odza', 'Centre Ville', 800),
  ('Boulevard du 20 mai', 'Kennedy', 200),
  ('Boulevard du 20 mai', 'Kondengui', 700),
  ('Boulevard du 20 mai', 'Biyem Assi', 700),
  ('Boulevard du 20 mai', 'Ekounou', 600),
  ('Boulevard du 20 mai', 'Dragage', 400),
  ('Boulevard du 20 mai', 'Playce', 200),
  ('Boulevard du 20 mai', 'Carrefour Intendance', 300),
  ('Boulevard du 20 mai', 'Tsinga', 400),
  ('Boulevard du 20 mai', 'Mvom Mbi', 300),
  ('Boulevard du 20 mai', 'Centre Ville', 200),
  ('Kennedy', 'Kondengui', 600),
  ('Kennedy', 'Biyem Assi', 700),
  ('Kennedy', 'Ekounou', 600),
  ('Kennedy', 'Dragage', 400),
  ('Kennedy', 'Playce', 300),
  ('Kennedy', 'Carrefour Intendance', 200),
  ('Kennedy', 'Tsinga', 300),
  ('Kennedy', 'Mvom Mbi', 300),
  ('Kennedy', 'Centre Ville', 200),
  ('Kondengui', 'Biyem Assi', 600),
  ('Kondengui', 'Ekounou', 300),
  ('Kondengui', 'Dragage', 800),
  ('Kondengui', 'Playce', 600),
  ('Kondengui', 'Carrefour Intendance', 400),
  ('Kondengui', 'Tsinga', 700),
  ('Kondengui', 'Mvom Mbi', 300),
  ('Kondengui', 'Centre Ville', 400),
  ('Biyem Assi', 'Ekounou', 800),
  ('Biyem Assi', 'Dragage', 800),
  ('Biyem Assi', 'Playce', 700),
  ('Biyem Assi', 'Carrefour Intendance', 500),
  ('Biyem Assi', 'Tsinga', 500),
  ('Biyem Assi', 'Mvom Mbi', 350),
  ('Biyem Assi', 'Centre Ville', 500),
  ('Ekounou', 'Dragage', 800),
  ('Ekounou', 'Playce', 700),
  ('Ekounou', 'Carrefour Intendance', 500),
  ('Ekounou', 'Tsinga', 800),
  ('Ekounou', 'Mvom Mbi', 500),
  ('Ekounou', 'Centre Ville', 700),
  ('Dragage', 'Playce', 500),
  ('Dragage', 'Carrefour Intendance', 500),
  ('Dragage', 'Tsinga', 500),
  ('Dragage', 'Mvom Mbi', 600),
  ('Dragage', 'Centre Ville', 500),
  ('Playce', 'Carrefour Intendance', 300),
  ('Playce', 'Tsinga', 200),
  ('Playce', 'Mvom Mbi', 350),
  ('Playce', 'Centre Ville', 200),
  ('Carrefour Intendance', 'Tsinga', 300),
  ('Carrefour Intendance', 'Mvom Mbi', 400),
  ('Carrefour Intendance', 'Centre Ville', 300),
  ('Tsinga', 'Mvom Mbi', 500),
  ('Tsinga', 'Centre Ville', 300),
  ('Mvom Mbi', 'Centre Ville', 400),
];
Map<String, int> _buildPriceMap(List<(String, String, int)> edges) {
  final m = <String, int>{};
  for (final e in edges) {
    final k = '${e.$1}|${e.$2}';
    final kr = '${e.$2}|${e.$1}';
    m[k] = e.$3;
    m.putIfAbsent(kr, () => e.$3);
  }
  return m;
}

final _mapDouala = _buildPriceMap(_trajetsDouala);
final _mapYaounde = _buildPriceMap(_trajetsYaounde);

List<(String, String, int)> _edgesForVille(VilleTransport? ville) {
  if (ville == 'Douala') return _trajetsDouala;
  if (ville == 'Yaoundé') return _trajetsYaounde;
  return const [];
}

List<String> getVillesTransport() => List.unmodifiable(villesTransport);

List<String> getQuartiersDepart(VilleTransport? ville) {
  final edges = _edgesForVille(ville);
  final s = <String>{};
  for (final e in edges) {
    s.add(e.$1);
    s.add(e.$2);
  }
  final list = s.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return list;
}

List<String> getQuartiersArrivee(VilleTransport? ville, String depart) {
  if (ville == null || ville.isEmpty || depart.isEmpty) return const [];
  final edges = _edgesForVille(ville);
  final dest = <String>{depart};
  for (final e in edges) {
    if (e.$1 == depart) dest.add(e.$2);
    if (e.$2 == depart) dest.add(e.$1);
  }
  final list = dest.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return list;
}

int montantMemeQuartierFcfa() => DateTime.now().millisecond.isEven ? 150 : 200;

int? getPrixTrajet(VilleTransport? ville, String quartierDepart, String quartierArrivee) {
  if (ville == null || ville.isEmpty || quartierDepart.isEmpty || quartierArrivee.isEmpty) {
    return null;
  }
  if (quartierDepart == quartierArrivee) return null;
  final map = ville == 'Douala'
      ? _mapDouala
      : ville == 'Yaoundé'
          ? _mapYaounde
          : null;
  if (map == null) return null;
  return map['$quartierDepart|$quartierArrivee'];
}

String? montantPourQuartiers(
  VilleTransport? ville,
  String quartierDepart,
  String quartierArrivee,
) {
  if (ville == null || ville.isEmpty || quartierDepart.isEmpty || quartierArrivee.isEmpty) {
    return null;
  }
  if (quartierDepart == quartierArrivee) {
    return '${montantMemeQuartierFcfa()}';
  }
  final price = getPrixTrajet(ville, quartierDepart, quartierArrivee);
  return price != null ? '$price' : null;
}
