import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/pending_event.dart';

class StoredEvent {
  const StoredEvent(this.key, this.event);

  final dynamic key;
  final PendingEvent event;
}

class PendingEventStore {
  PendingEventStore._(this._box) {
    pendingCount.value = _box.length;
  }

  static const _boxName = 'pending_events';

  final Box<String> _box;
  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  static Future<PendingEventStore> open() async {
    final box = await Hive.openBox<String>(_boxName);
    return PendingEventStore._(box);
  }

  bool get isEmpty => _box.isEmpty;

  Future<void> add(PendingEvent event) async {
    await _box.add(jsonEncode(event.toMap()));
    pendingCount.value = _box.length;
  }

  StoredEvent? oldest() {
    if (_box.isEmpty) return null;
    final keys = _box.keys.toList()..sort((a, b) => (a as int).compareTo(b as int));
    final key = keys.first;
    final raw = _box.get(key)!;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return StoredEvent(key, PendingEvent.fromMap(map));
  }

  Future<void> remove(dynamic key) async {
    await _box.delete(key);
    pendingCount.value = _box.length;
  }
}
