import '../models/tache.dart';

// Aligné sur le CRM web (`task-rules.ts` + `AllTasksView.tsx`).

const statutEnCours = 'En cours';
const statutTermine = 'Terminé';
const statutNonDefini = 'Non défini';
const statutNonFaite = 'Non faite';

enum TaskStatutNormalized { enCours, termine, nonDefini, nonFaite }

/// Limite d’échéance future pour l’onglet « En cours » (J+7, comme le web).
const taskActiveFutureDueDays = 7;

TaskStatutNormalized normalizeTaskStatut(String? raw) {
  if (raw == null) return TaskStatutNormalized.nonDefini;
  final t = raw.trim();
  if (t.isEmpty) return TaskStatutNormalized.nonDefini;
  final lower = t.toLowerCase();
  if (lower == 'en cours') return TaskStatutNormalized.enCours;
  if (lower == 'terminé' ||
      lower == 'termine' ||
      lower == 'terminée' ||
      lower == 'terminee') {
    return TaskStatutNormalized.termine;
  }
  if (lower == 'non faite') return TaskStatutNormalized.nonFaite;
  if (lower == 'non défini' || lower == 'non defini') {
    return TaskStatutNormalized.nonDefini;
  }
  return TaskStatutNormalized.nonDefini;
}

bool isClosedStatut(String? raw) {
  final n = normalizeTaskStatut(raw);
  return n == TaskStatutNormalized.termine ||
      n == TaskStatutNormalized.nonDefini;
}

bool isTaskClosed(Tache t) => isClosedStatut(t.statut);

bool isTaskDoneForObjectives(Tache t) =>
    normalizeTaskStatut(t.statut) == TaskStatutNormalized.termine;

/// Tâche visible dans « Mes tâches sélectionnées » (rappels web).
bool isSelectedRappelTask(Tache t) {
  if (!t.isSelectionnee) return false;
  final n = normalizeTaskStatut(t.statut);
  return n != TaskStatutNormalized.termine &&
      n != TaskStatutNormalized.nonDefini &&
      n != TaskStatutNormalized.nonFaite;
}

/// Liste « En cours » : ouvertes, hors sélectionnées, échéance ≤ J+7.
bool taskMatchesActiveList(
  Tache t, {
  int limitFutureDueDateDays = taskActiveFutureDueDays,
}) {
  if (isTaskClosed(t)) return false;
  if (t.isSelectionnee) return false;
  if (!isTaskDueWithinFutureDays(t.dateButoire, limitFutureDueDateDays)) {
    return false;
  }
  return true;
}

/// Historique : tâches clôturées (Terminé + Non défini).
bool taskMatchesHistoryList(Tache t) => isTaskClosed(t);

int _parseIsoMs(String? iso) {
  if (iso == null || iso.isEmpty) return 0;
  final normalized =
      iso.contains('T') ? iso : iso.replaceFirst(' ', 'T');
  final ms = DateTime.tryParse(normalized)?.millisecondsSinceEpoch;
  return ms ?? 0;
}

/// Tri historique : plus récent en premier (fin réelle, sinon mise à jour).
int historyClosureSortMs(Tache t) {
  if (normalizeTaskStatut(t.statut) == TaskStatutNormalized.termine &&
      t.dateTerminee != null) {
    final ms = _parseIsoMs(t.dateTerminee);
    if (ms > 0) return ms;
  }
  final updated = _parseIsoMs(t.updatedAt);
  if (updated > 0) return updated;
  return _parseIsoMs(t.createdAt);
}

int selectedRappelSortMs(Tache t) =>
    _parseIsoMs(t.dateSelection) > 0
        ? _parseIsoMs(t.dateSelection)
        : _parseIsoMs(t.createdAt);

/// True si pas de date, échéance passée/aujourd'hui, ou échéance future ≤ J+`daysAhead`.
bool isTaskDueWithinFutureDays(
  String? dateButoire,
  int daysAhead, [
  DateTime? now,
]) {
  final due = _parseDueDate(dateButoire);
  if (due == null) return true;

  final today = now ?? DateTime.now();
  final todayStart = DateTime(today.year, today.month, today.day);
  final dueStart = DateTime(due.year, due.month, due.day);
  if (!dueStart.isAfter(todayStart)) return true;

  final maxDate = todayStart.add(Duration(days: daysAhead));
  return !dueStart.isAfter(maxDate);
}

DateTime? _parseDueDate(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final iso = raw.length >= 10 ? raw.substring(0, 10) : raw;
  return DateTime.tryParse(iso);
}
