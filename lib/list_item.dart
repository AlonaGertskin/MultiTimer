import 'dart:async';
import 'dart:convert';
import 'chain_model.dart';
import 'timer_model.dart';

abstract interface class ListItem {
  int get id;
  bool get isRunning;
  DateTime? get endTime;
  Timer? get internalTimer;
  void syncWithClock();
  Map<String, dynamic> toMap();

  static List<ListItem> listFromJson(String json, {DateTime Function()? now}) {
    final List<dynamic> decoded;
    try {
      decoded = jsonDecode(json) as List<dynamic>;
    } catch (_) {
      return [];
    }

    final items = <ListItem>[];
    for (final entry in decoded) {
      try {
        final map = entry as Map<String, dynamic>;
        items.add(
          map['type'] == 'chain'
              ? ChainModel.fromMap(map, now: now)
              : TimerModel.fromMap(map, now: now),
        );
      } catch (_) {
        continue;
      }
    }
    return items;
  }
}
