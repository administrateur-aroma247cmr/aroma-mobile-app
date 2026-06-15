import '../../utils/format_utils.dart';

String formatKpiNumber(num value, {bool compact = false}) {
  final v = value.toDouble();
  if (compact) {
    if (v.abs() >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(1)}M';
    }
    if (v.abs() >= 1000) {
      return '${(v / 1000).toStringAsFixed(1)}k';
    }
  }
  if (v == v.roundToDouble()) return v.round().toString();
  return v.toStringAsFixed(1);
}

String formatPct(num? value) {
  if (value == null) return '—';
  final v = value.toDouble();
  if (v == v.roundToDouble()) return '${v.round()} %';
  return '${v.toStringAsFixed(1)} %';
}

String formatVolumeMl(num value, {bool compact = false}) {
  final v = value.toDouble();
  if (v >= 1000) {
    final litres = v / 1000;
    if (litres == litres.roundToDouble()) {
      return '${litres.round()} L';
    }
    return '${litres.toStringAsFixed(1)} L';
  }
  return '${formatKpiNumber(v, compact: compact)} ml';
}

String formatKpiAxisTick(double value) => formatKpiNumber(value, compact: true);

String formatFcfa(num? value) => fmtFcfa(value);

String formatControleValue(double value, String? unite) {
  switch (unite) {
    case 'fcfa':
      return fmtFcfa(value);
    case 'heures':
      return '${formatKpiNumber(value)} h';
    case 'jours':
      return '${formatKpiNumber(value)} j';
    case 'pct':
      return formatPct(value);
    default:
      return formatKpiNumber(value);
  }
}
